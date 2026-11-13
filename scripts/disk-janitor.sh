#!/bin/bash
# Disk janitor v3: reclaim regenerable artifacts, including out-of-tree targets.
# - Scans deeper than v2 and covers relocated target dirs (.targets, builds, ~/.cargo/target)
# - Removes build dirs idle >=24h (>=5min when free <25G; anything not written this minute
#   when free <10G)
# - Re-injects shared cargo target-dir into fresh clones
# - Cleans /tmp scratch, checkpoints opencode WAL
# Never touches source files, ~/data, models, or a dir being written to.
LOG=/home/wyatt/.cache/janitor.log
SHARED_TARGET=/home/wyatt/.cache/cargo-target
ROOTS="/home/wyatt/dev/src /home/wyatt/dev/.targets /home/wyatt/builds /home/wyatt/.cargo/target"

{
echo "=== janitor v3 run $(date) ==="
free_g=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
echo "free before: ${free_g}G"
if   [ "$free_g" -lt 10 ]; then idle="1 minute ago";   mode="EMERGENCY"
elif [ "$free_g" -lt 25 ]; then idle="5 minutes ago";  mode="pressured"
else                           idle="24 hours ago";   mode="normal"
fi
echo "mode: $mode (idle threshold: $idle)"

# Only ever removes: cargo `target` dirs, Lean `.lake` dirs, and *evidence-backed*
# build output dirs (CACHEDIR.TAG or CMakeCache.txt present, or nested under target/).
# Never touches anything inside node_modules/ or a vendored dependency tree —
# those contain real source files that happen to live in a dir called "build".
is_artifact_dir() {
  local t="$1"
  case "$t" in
    */node_modules/*|*/vendor/*|*/.git/*) return 1 ;;
  esac
  case "$(basename "$t")" in
    .lake) return 0 ;;
    target) return 0 ;;
    build)
      [ -f "$t/CACHEDIR.TAG" ] || [ -f "$t/CMakeCache.txt" ] && return 0
      case "$t" in */target/*) return 0 ;; esac
      return 1 ;;
  esac
  return 1
}

sweep() { # $1 = search root
  local root="$1"
  [ -d "$root" ] || return 0
  while IFS= read -r t; do
    is_artifact_dir "$t" || continue
    local recent sz
    recent=$(find "$t" -type f -newermt "$idle" 2>/dev/null | wc -l)
    if [ "$recent" -eq 0 ]; then
      sz=$(du -sh "$t" 2>/dev/null | cut -f1)
      rm -rf "$t" && echo "removed idle ($sz): $t"
    fi
  done < <(find "$root" -maxdepth 9 -type d \( -name target -o -name build -o -name .lake \) -prune 2>/dev/null)
}

for r in $ROOTS; do sweep "$r"; done

# idle node_modules (>14 days untouched) - regenerable via the project's package manager
while IFS= read -r nm; do
  [ "$(find "$nm" -type f -newermt '14 days ago' 2>/dev/null | wc -l)" -eq 0 ] && \
    { sz=$(du -sh "$nm" 2>/dev/null | cut -f1); rm -rf "$nm" && echo "removed stale node_modules ($sz): $nm"; }
done < <(find /home/wyatt/dev -maxdepth 8 -type d -name node_modules -prune 2>/dev/null)

# re-inject shared target-dir into cargo workspaces that don't have one
fixed=0
for cm in $(find /home/wyatt/dev/src -maxdepth 4 -name Cargo.toml 2>/dev/null); do
  d=$(dirname "$cm"); cfg="$d/.cargo/config.toml"
  grep -q "target-dir" "$cfg" 2>/dev/null && continue
  mkdir -p "$d/.cargo"
  if [ -f "$cfg" ] && grep -q "^\[build\]" "$cfg"; then
    sed -i "s|^\[build\]|[build]\ntarget-dir = \"$SHARED_TARGET\"|" "$cfg"
  else
    printf '\n[build]\ntarget-dir = "%s"\n' "$SHARED_TARGET" >> "$cfg"
  fi
  fixed=$((fixed+1))
done
echo "target-dir injected into $fixed repos"

# /tmp hygiene
find /tmp/opencode -maxdepth 1 -mindepth 1 -mtime +1 -exec rm -rf {} \; 2>/dev/null
find /tmp -maxdepth 1 -mindepth 1 -mtime +3 -exec rm -rf {} \; 2>/dev/null

# tmpfs guard: agents relocate cargo targets into /tmp/opencode/*-target.
# The tmpfs is 16G — an 11G target nearly filled it (2026-11-12). Fleet rule:
# heavy builds never live in /tmp. Reap relocated target dirs idle >1h.
find /tmp/opencode -maxdepth 1 -type d -name "*-target" -mmin +60 -exec rm -rf {} \; 2>/dev/null

# same guard for relocated targets in ~/.cache (zz-camp-target etc.) —
# the sweep above only matches dirs named exactly "target"
find /home/wyatt/.cache -maxdepth 1 -type d -name "*-target" ! -name "cargo-target" -mmin +60 -exec rm -rf {} \; 2>/dev/null

# opencode WAL guard
wal=/home/wyatt/.local/share/opencode/opencode.db-wal
if [ -f "$wal" ]; then
  walsz=$(stat -c %s "$wal" 2>/dev/null || echo 0)
  if [ "$walsz" -gt 2000000000 ]; then
    sqlite3 /home/wyatt/.local/share/opencode/opencode.db "PRAGMA busy_timeout=30000; PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1
    echo "wal checkpointed (was $((walsz/1000000))MB)"
  fi
fi

# 7. shared target cap: past ~100G it's mostly cold artifacts — a rebuild is
#    cheaper than the disk it holds. Only when fully idle for 6h+.
if [ -d "$SHARED_TARGET" ]; then
  cap_kb=$(du -sk "$SHARED_TARGET" 2>/dev/null | cut -f1)
  recent=$(find "$SHARED_TARGET" -type f -newermt '6 hours ago' 2>/dev/null | wc -l)
  if [ "${cap_kb:-0}" -gt 104857600 ] && [ "$recent" -eq 0 ]; then
    rm -rf "$SHARED_TARGET" && echo "capped shared target (was $((cap_kb/1048576))G, idle >6h)"
  fi
fi

echo "=== after ==="
df -h / | tail -1
} >> "$LOG" 2>&1
