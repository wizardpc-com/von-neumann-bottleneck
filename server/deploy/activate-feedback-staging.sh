#!/usr/bin/env bash
# Activate a frozen, already extracted staging release while keeping the live SQLite file.
set -euo pipefail

revision=${1:-}
if [[ $EUID != 0 || ! $revision =~ ^[a-f0-9]{40}$ ]]; then
    echo 'Usage: sudo bash activate-feedback-staging.sh FULL_COMMIT_SHA' >&2
    exit 2
fi

base=/srv/ray/apps/vnb
current="$base/current-staging"
target="$base/staging-releases/$revision"
receiver=vnb-feedback-staging.service
proxy=vnb-feedback-staging-proxy.service
exec 9>/run/lock/vnb-feedback-staging.lock
flock -n 9

previous=$(readlink "$current")
if [[ ! $previous =~ ^"$base"/staging-releases/[a-f0-9]{40}$ ]] ||
   [[ ! -f "$previous/server/feedback_server.py" || ! -f "$target/server/feedback_server.py" ]] ||
   [[ $(realpath "$target") != "$target" ]]; then
    echo 'Current or requested staging release is missing or outside the release directory' >&2
    exit 2
fi
systemctl is-active --quiet "$receiver"
systemctl is-active --quiet "$proxy"

switch_to() {
    local link_dir
    link_dir=$(mktemp -d "$base/.staging-link.XXXXXX")
    if ln -s "$1" "$link_dir/current" && mv -Tf "$link_dir/current" "$current"; then
        rmdir "$link_dir"
    else
        rm -f "$link_dir/current"
        rmdir "$link_dir"
        return 1
    fi
}

healthy() {
    local attempt
    for attempt in {1..15}; do
        if curl --noproxy '*' --max-time 2 -fsS http://127.0.0.1:28081/v1/health 2>/dev/null |
           python3 -c 'import json,sys; h=json.load(sys.stdin); sys.exit(not (h.get("ok") is True and h.get("api_version")==1 and h.get("schema_version")==2))' 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    return 1
}

if [[ $previous == "$target" ]]; then
    healthy
    exit
fi
if switch_to "$target" && systemctl restart "$receiver" && healthy && systemctl is-active --quiet "$proxy"; then
    echo "Staging active: $revision"
    exit
fi
echo "Staging activation failed; restoring ${previous##*/}" >&2
if ! switch_to "$previous" || ! systemctl restart "$receiver" || ! healthy || ! systemctl is-active --quiet "$proxy"; then
    echo 'Staging rollback health failed; stopping staging ingress' >&2
    systemctl stop "$proxy"
fi
exit 1
