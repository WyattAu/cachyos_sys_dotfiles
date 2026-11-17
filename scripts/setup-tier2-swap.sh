#!/bin/bash
# setup-tier2-swap.sh — permanent 32G disk swap at lower priority than zram.
#
# Purpose: on machines whose working set exceeds physical RAM, zram hits 100%
# and the box thrashes (kswapd churn, load spike, lag). With a tier-2 disk
# swap at priority 50 (below zram's 100), the kernel keeps hot pages in
# compressed zram and parks cold pages on disk — zram stops saturating.
#
# The swapfile lives in /home (subvolume @home), which is NOT covered by the
# snapper root-snapshot config, so snapshots never interact with it.
# btrfs-safe: NOCOW attribute set before any data is written.
#
# Run with: sudo setup-tier2-swap.sh [sizeG]   (default 32G)
set -euo pipefail

[ "$(id -u)" -ne 0 ] && { echo "run me with sudo"; exit 1; }
SWFILE=/home/swapfile-tier2
G="${1:-32}"

echo ">> checking for existing setup"
if swapon --show=NAME --noheadings | grep -qx "$SWFILE"; then
  echo "already active: $SWFILE"; swapon --show; exit 0
fi

if [ -f "$SWFILE" ] && [ "$(stat -c %s "$SWFILE")" -eq "$((G*1024*1024*1024))" ]; then
  echo ">> reusing existing ${G}GiB file"
else
  echo ">> creating ${G}GiB NOCOW swapfile at $SWFILE"
  rm -f "$SWFILE"
  ( touch "$SWFILE" && chattr +C "$SWFILE" && chmod 600 "$SWFILE" && \
    dd if=/dev/zero of="$SWFILE" bs=1M count=$((G*1024)) status=progress ) \
    || { rm -f "$SWFILE"; echo "creation failed"; exit 1; }
  mkswap -L tier2 "$SWFILE" >/dev/null
fi

echo ">> activating at priority 50 (zram stays at 100 = preferred)"
swapon -v -p 50 "$SWFILE"

if ! grep -q "^$SWFILE" /etc/fstab; then
  cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
  echo "$SWFILE none swap defaults,pri=50 0 0" >> /etc/fstab
  echo ">> added to /etc/fstab (backup written)"
fi

echo
echo "=== result ==="
swapon --show
free -h | sed -n '1,3p'
