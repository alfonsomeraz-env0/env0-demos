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


def jupyter(path):
    request = urllib.request.Request(JUPYTER_API + path)
    with urllib.request.urlopen(request, context=SSL_CTX, timeout=10) as response:
        return json.load(response)


def seconds_since(timestamp):
    """Parse a Jupyter ISO-8601 timestamp, with or without microseconds."""
    normalized = timestamp.replace("Z", "+00:00")
    if "." not in normalized:
        normalized = normalized.replace("+00:00", ".000000+00:00")
    parsed = datetime.strptime(normalized, "%Y-%m-%dT%H:%M:%S.%f%z")
    return (datetime.now(timezone.utc) - parsed).total_seconds()


def is_idle():
    sessions = jupyter("sessions")
    if not sessions:
        return True

    for session in sessions:
        kernel = session.get("kernel", {})
        if kernel.get("execution_state") != "idle":
            return False
        if seconds_since(kernel["last_activity"]) < IDLE_SECONDS:
            return False

    return True


def main():
    if not is_idle():
        return 0

    with open(METADATA) as handle:
        name = json.load(handle)["ResourceName"]

    print("kernels idle for over %ds — stopping %s" % (IDLE_SECONDS, name))
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
