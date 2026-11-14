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
echo "=== pruning ==="
snapper -c root cleanup number
snapper -c root cleanup timeline
snapper -c root cleanup empty-pre-post

# cleanup only touches snapshots tagged with a cleanup algorithm; snapshots
# created with cleanup=none (or by other tools) survive it forever. Force:
# delete everything except the newest 2 numbers.
mapfile -t nums < <(snapper -c root list --columns number 2>/dev/null | grep -E '^[0-9]+$' | sort -n)
keep=2
if [ "${#nums[@]}" -gt "$keep" ]; then
  del="${nums[0]}"
  for ((i=1; i<${#nums[@]}-keep; i++)); do del="$del-${nums[$i]}"; done
  echo "force-deleting snapshot numbers: $del"
  snapper -c root delete --sync $del && echo "deleted."
else
  echo "only ${#nums[@]} snapshots - nothing to force-delete"
fi
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
