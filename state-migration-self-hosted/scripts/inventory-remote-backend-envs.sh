#!/usr/bin/env bash
# Counts env0 environments using the env0 remote backend, grouped by project.
# This is your pre-migration scope + the reconciliation checklist env0 support
# will check the post-cutover state count against.
#
# Requires: ENV0_API_KEY (bearer token), ENV0_ORGANIZATION_ID
set -euo pipefail

: "${ENV0_API_KEY:?Set ENV0_API_KEY to an env0 API token}"
: "${ENV0_ORGANIZATION_ID:?Set ENV0_ORGANIZATION_ID to your env0 org ID}"

curl -s -H "Authorization: Bearer ${ENV0_API_KEY}" \
  "https://api.env0.com/environments?organizationId=${ENV0_ORGANIZATION_ID}" \
  | jq '[.[] | select(.useRemoteBackend == true)] | group_by(.projectId) | map({project: .[0].projectId, count: length})'
