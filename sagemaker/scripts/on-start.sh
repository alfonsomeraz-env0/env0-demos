#!/bin/bash
# SageMaker notebook lifecycle configuration — on-start hook.
# Rendered by OpenTofu with an idle timeout of ${idle_timeout_minutes} minutes.
#
# Installs a cron job that stops this notebook instance once every Jupyter
# kernel has been idle for longer than the timeout. Lifecycle scripts always
# run as root, so this works even when root_access is Disabled for users.
#
# Lifecycle scripts must finish within 5 minutes or the notebook fails to start.

set -uo pipefail

IDLE_SECONDS=$((${idle_timeout_minutes} * 60))
AUTOSTOP=/usr/local/bin/notebook-autostop.py
LOG=/var/log/notebook-autostop.log

cat > "$AUTOSTOP" <<'PYEOF'
#!/usr/bin/env python3
"""Stop this notebook instance when all of its kernels have gone idle."""

import json
import ssl
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone

IDLE_SECONDS = int(sys.argv[1])
JUPYTER_API = "https://localhost:8443/api/"
METADATA = "/opt/ml/metadata/resource-metadata.json"

# The local Jupyter server uses a self-signed certificate.
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE


def jupyter(path, default=None):
    request = urllib.request.Request(JUPYTER_API + path)
    try:
        with urllib.request.urlopen(request, context=SSL_CTX, timeout=10) as response:
            return json.load(response)
    except Exception as err:
        if default is None:
            raise
        print("GET %s failed (%s) — treating as %r" % (path, err, default))
        return default


def seconds_since(timestamp):
    """Parse a Jupyter ISO-8601 timestamp, with or without microseconds."""
    normalized = timestamp.replace("Z", "+00:00")
    if "." not in normalized:
        normalized = normalized.replace("+00:00", ".000000+00:00")
    parsed = datetime.strptime(normalized, "%Y-%m-%dT%H:%M:%S.%f%z")
    return max(0.0, (datetime.now(timezone.utc) - parsed).total_seconds())


def busy_kernel(sessions):
    for session in sessions:
        state = session.get("kernel", {}).get("execution_state")
        if state and state != "idle":
            return True
    return False


def seconds_since_last_activity(status, sessions, terminals):
    """Age of the most recent activity on the instance.

    The server's own start time is included as a floor. Without it, a notebook
    that nobody has opened yet reports no sessions and no kernels, which reads
    as "idle forever" and gets the instance stopped on the first cron tick
    after boot. With it, a fresh notebook gets a full idle window.

    Deliberately does not use the server's `last_activity` field: Jupyter
    refreshes that on authenticated API requests, so this script's own polling
    could keep resetting it and silently prevent shutdown altogether.
    """
    stamps = [status["started"]]
    stamps += [s["kernel"]["last_activity"] for s in sessions if s.get("kernel")]
    stamps += [t["last_activity"] for t in terminals if t.get("last_activity")]

    return min(seconds_since(stamp) for stamp in stamps)


def main():
    try:
        status = jupyter("status")
        sessions = jupyter("sessions")
    except Exception as err:
        print("Jupyter API unreachable (%s) — leaving the notebook running" % err)
        return 0

    # Terminals can be disabled outright, so a failure here is not fatal.
    terminals = jupyter("terminals", default=[])

    if busy_kernel(sessions):
        print("a kernel is busy — leaving the notebook running")
        return 0

    idle_for = seconds_since_last_activity(status, sessions, terminals)
    if idle_for < IDLE_SECONDS:
        print("last activity %ds ago, under the %ds limit" % (idle_for, IDLE_SECONDS))
        return 0

    with open(METADATA) as handle:
        name = json.load(handle)["ResourceName"]

    print("idle for %ds (limit %ds) — stopping %s" % (idle_for, IDLE_SECONDS, name))
    subprocess.run(
        ["aws", "sagemaker", "stop-notebook-instance", "--notebook-instance-name", name],
        check=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
PYEOF

chmod 0755 "$AUTOSTOP"

# cron runs with a minimal PATH, so pin the one the AWS CLI lives on.
CRON_LINE="*/5 * * * * PATH=/usr/local/bin:/usr/bin:/bin /usr/bin/python3 $AUTOSTOP $IDLE_SECONDS >> $LOG 2>&1"

# Replace any entry from a previous start rather than stacking duplicates.
{ crontab -l 2>/dev/null | grep -v notebook-autostop.py; echo "$CRON_LINE"; } | crontab -

systemctl enable --now crond 2>/dev/null || true

echo "auto-shutdown installed — idle timeout ${idle_timeout_minutes} minutes"
