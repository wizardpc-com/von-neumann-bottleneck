#!/bin/sh
# Populate the dedicated process environment after systemd has loaded the credential.
# Caddy keeps only the runtime placeholder in its adapted/autosaved configuration.
set +x
set -eu
IFS= read -r VNB_FEEDBACK_EDGE_TOKEN < "${CREDENTIALS_DIRECTORY:?}/edge.token"
case "$VNB_FEEDBACK_EDGE_TOKEN" in
    *[!0-9a-f]*|'') exit 1 ;;
esac
[ "${#VNB_FEEDBACK_EDGE_TOKEN}" -eq 64 ]
export VNB_FEEDBACK_EDGE_TOKEN
exec "$@"
