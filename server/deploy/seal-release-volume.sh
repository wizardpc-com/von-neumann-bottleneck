#!/bin/sh
# Preserve the backing image allocation across periodic host discard.
set -eu
case "${1:-}" in
    live) size=$((1 * 1024 * 1024 * 1024)) ;;
    ops) size=$((3 * 1024 * 1024 * 1024)) ;;
    *) exit 1 ;;
esac
root=/srv/ray/vnb_release
image=$root/images/$1.img
device=$(findmnt --noheadings --output SOURCE --mountpoint "$root/$1")
case "$device" in
    /dev/loop*) number=${device#/dev/loop} ;;
    *) exit 1 ;;
esac
case "$number" in
    ''|*[!0-9]*) exit 1 ;;
esac
test "$(losetup --noheadings --output BACK-FILE "$device")" = "$image"
discard=/sys/class/block/loop$number/queue/discard_max_bytes
printf '0\n' > "$discard"
test "$(cat "$discard")" = 0
set -- $(stat -c '%s %b' "$image")
test "$1" -eq "$size"
test "$(($2 * 512))" -ge "$size"
