#!/bin/bash
# Reclaim space held by btrfs/snapper snapshots on the root subvolume.
# Run with: sudo bash /home/wyatt/.local/bin/reclaim-snapshots.sh [--dry-run]
# Safe: uses snapper's own cleanup logic, keeps the newest snapshots and any
# snapshot marked "important". Never touches files, only snapshot metadata.
set -u

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

[ "$(id -u)" -ne 0 ] && { echo "run me with sudo"; exit 1; }

CFG=/etc/snapper/configs/root

echo "=== BEFORE ==="
df -h / | tail -1
btrfs filesystem usage / | sed -n '1,10p'
echo
echo "=== current snapshots ==="
snapper -c root list 2>/dev/null | tail -n +3 | wc -l | xargs echo "snapshot count:"
snapper -c root list 2>/dev/null | tail -n +3 | head -5

if [ "$DRY" -eq 1 ]; then
  echo
  echo "[dry-run] would set: NUMBER_LIMIT=3 NUMBER_LIMIT_IMPORTANT=2 HOURLY=2 DAILY=2"
  echo "[dry-run] would run: snapper cleanup number/timeline/empty-pre-post, then balance -dusage=40"
  exit 0
fi

echo
echo "=== tightening retention ==="
cp -a "$CFG" "$CFG.bak.$(date +%Y%m%d%H%M%S)"
sed -i \
  -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="3"/' \
  -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="2"/' \
  -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="2"/' \
  -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="2"/' \
  "$CFG"
grep -E '^(NUMBER_LIMIT|NUMBER_LIMIT_IMPORTANT|TIMELINE_LIMIT_HOURLY|TIMELINE_LIMIT_DAILY)=' "$CFG"

echo
echo "=== pruning (this is the step that actually frees blocks) ==="
snapper -c root cleanup number
snapper -c root cleanup timeline
snapper -c root cleanup empty-pre-post
echo "snapshots left: $(snapper -c root list 2>/dev/null | tail -n +3 | wc -l)"

echo
echo "=== AFTER PRUNE ==="
df -h / | tail -1

echo
echo "=== collapsing half-empty chunks (may take 30-90 min) ==="
btrfs balance start -dusage=40 /

echo
echo "=== FINAL ==="
df -h / | tail -1
btrfs filesystem usage / | sed -n '1,10p'
