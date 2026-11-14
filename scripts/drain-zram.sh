#!/bin/bash
# drain-zram.sh — empty a full zram swap device WITHOUT rebooting.
#
# How: create a temporary disk swapfile, swapoff the zram (the kernel migrates
# every swapped page into RAM + the swapfile), swapon a fresh zram, then pull
# the pages back and delete the swapfile.
#
# Run with: sudo drain-zram.sh
set -u

[ "$(id -u)" -ne 0 ] && { echo "run me with sudo"; exit 1; }
ZRAM=/dev/zram0
[ -b "$ZRAM" ] || { echo "no $ZRAM"; exit 1; }

# /proc/swaps: Filename Type Size Used Priority (sizes in KB)
used_bytes=$(awk -v d="$ZRAM" '$1==d {print $4*1024; exit}' /proc/swaps)
used_g=$(( used_bytes / 1073741824 ))
avail_mb=$(free -m | awk '/^Mem:/{print $7}')
echo "zram swap used: ${used_g}G | RAM available: ${avail_mb}M"

if [ "$avail_mb" -lt 4000 ]; then
  echo "less than 4G RAM available - close some apps first"; exit 1
fi

# swapfile big enough for everything RAM cannot absorb
file_g=$(( used_g + 4 )); [ "$file_g" -lt 8 ] && file_g=8
SWFILE=/swapfile-drain
echo ">> creating ${file_g}G swapfile at $SWFILE (btrfs NOCOW)"
truncate -s "${file_g}G" "$SWFILE"
chattr +C "$SWFILE" 2>/dev/null
mkswap -L drain "$SWFILE" >/dev/null
swapon -v "$SWFILE" || { rm -f "$SWFILE"; echo "could not activate swapfile"; exit 1; }

echo ">> swapoff $ZRAM — this migrates all swapped pages; takes a few minutes"
if ! swapoff "$ZRAM"; then
  echo "swapoff failed - leaving swapfile active as fallback"; exit 1
fi

echo ">> swapon fresh $ZRAM"
swapon -v -p 100 "$ZRAM"

echo ">> pulling pages back: swapoff $SWFILE"
if swapoff "$SWFILE" 2>/dev/null; then
  swapoff_ok=1
else
  swapoff_ok=0
  echo "not enough RAM to absorb the swapfile - leaving it active (harmless)"
fi

[ "$swapoff_ok" -eq 1 ] && rm -f "$SWFILE" && echo ">> swapfile removed"

echo
echo "=== result ==="
swapon --show
free -h | sed -n '1,2p'
