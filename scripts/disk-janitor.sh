#!/bin/bash
# Disk janitor v3: reclaim regenerable artifacts, including out-of-tree targets.
# - Scans deeper than v2 and covers relocated target dirs (.targets, builds, ~/.cargo/target)
# - Removes build dirs idle >=24h (>=5min when free <25G; anything not written this minute
#   when free <10G)
# - Re-injects shared cargo target-dir into fresh clones
# - Cleans /tmp scratch, checkpoints opencode WAL
# Never touches source files, ~/data, models, or a dir being written to.
LOG="${JANITOR_LOG:-${XDG_CACHE_HOME:-$HOME/.cache}/janitor.log}"
SHARED_TARGET="${JANITOR_SHARED_TARGET:-${XDG_CACHE_HOME:-$HOME/.cache}/cargo-target}"
ROOTS="${JANITOR_ROOTS:-$HOME/dev/src $HOME/dev/.targets $HOME/builds $HOME/.cargo/target}"

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

# Cargo incremental caches inside the shared target: regenerable,
# grow unbounded (26G observed), and never match the artifact sweep
# (they live inside cargo-target/, not a dir named `target`).
for inc in "$SHARED_TARGET/debug/incremental" "$SHARED_TARGET/release/incremental"; do
  [ -d "$inc" ] || continue
  recent=$(find "$inc" -type f -newermt "$idle" 2>/dev/null | wc -l)
  if [ "$recent" -eq 0 ]; then
    sz=$(du -sh "$inc" 2>/dev/null | cut -f1)
    rm -rf "$inc" && echo "removed idle incremental ($sz): $inc"
  fi
done

# Out-of-tree target roots. Some loops run cargo with --target-dir pointing at
# $HOME/dev/.targets/<name> (and ~/.cache/<name>-target). Those dirs are not
# named `target`, so the sweep above never matches them — a 183G loop dir
# filled the disk on 2026-11-21. Treat each top-level child as an artifact
# root: remove it when untouched for the tiered idle window, or when it is
# huge (>40G) and cold (>6h). Never remove a root some process still
# references, and never touch .targets/logs.
sweep_target_root() {
  local d="$1" sz_kb recent idle6
  [ -d "$d" ] || return 0
  pgrep -f "$d/" >/dev/null 2>&1 && { echo "kept in-use: $d"; return 0; }
  sz_kb=$(du -sk "$d" 2>/dev/null | cut -f1)
  recent=$(find "$d" -type f -newermt "$idle" 2>/dev/null | wc -l)
  if [ "$recent" -eq 0 ]; then
    rm -rf "$d" && echo "removed idle target root ($((sz_kb/1024))M): $d"
    return 0
  fi
  if [ "${sz_kb:-0}" -gt 41943040 ]; then
    idle6=$(find "$d" -type f -newermt '6 hours ago' 2>/dev/null | wc -l)
    if [ "$idle6" -eq 0 ]; then
      rm -rf "$d" && echo "capped cold target root (was $((sz_kb/1048576))G, idle >6h): $d"
    fi
  fi
}

for d in "$HOME/dev/.targets"/*/; do
  [ -d "$d" ] || continue
  case "$(basename "$d")" in logs) continue ;; esac
  sweep_target_root "${d%/}"
done

# same for ~/.cache/<name>-target variants (cargo-target-gui, cargo-target-196,
# zz-camp-target, ...) — the shared cargo-target keeps its own 100G cap below
for d in "$HOME/.cache"/*target*/; do
  [ -d "$d" ] || continue
  case "${d%/}" in "$SHARED_TARGET") continue ;; esac
  sweep_target_root "${d%/}"
done

# idle node_modules (>14 days untouched) - regenerable via the project's package manager
while IFS= read -r nm; do
  [ "$(find "$nm" -type f -newermt '14 days ago' 2>/dev/null | wc -l)" -eq 0 ] && \
    { sz=$(du -sh "$nm" 2>/dev/null | cut -f1); rm -rf "$nm" && echo "removed stale node_modules ($sz): $nm"; }
done < <(find "$HOME/dev" -maxdepth 8 -type d -name node_modules -prune 2>/dev/null)

# re-inject shared target-dir into cargo workspaces that don't have one.
fixed=0
# Word splitting is intentional here: dev checkout trees contain no spaces,
# and the Cargo.toml discovery is bounded to maxdepth 4.
# shellcheck disable=SC2044
for cm in $(find "$HOME/dev/src" -maxdepth 4 -name Cargo.toml 2>/dev/null); do
  d=$(dirname "$cm"); cfg="$d/.cargo/config.toml"
  grep -q "target-dir" "$cfg" 2>/dev/null && continue
  mkdir -p "$d/.cargo"
  printf '[build]\ntarget-dir = "%s"\n' "$SHARED_TARGET" > "$cfg" && fixed=$((fixed+1))
  # the absolute path is machine-specific — keep it out of git locally
  # (.git/info/exclude is invisible to CI and survives `git add -A`)
  repo=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$repo" ]; then
    ex="$repo/.git/info/exclude"
    grep -qxF ".cargo/config.toml" "$ex" 2>/dev/null || echo ".cargo/config.toml" >> "$ex"
  fi
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
find "${XDG_CACHE_HOME:-$HOME/.cache}" -maxdepth 1 -type d -name "*-target" ! -name "cargo-target" -mmin +60 -exec rm -rf {} \; 2>/dev/null

# tmpfs guard #2: big agent scratch in /tmp/opencode that isn't a build dir.
# 14G of downloaded Sentinel-1 SAFE archives sat there 9h and took the 16G
# tmpfs to 97% (2026-11-21) — fleet rule says heavy data never lives in /tmp.
# Reap any /tmp/opencode child >2G with nothing written in 60min; when the
# tmpfs itself is nearly full (<2G free), reap anything idle >5min.
tmpfs_free_mb=$(df -BM --output=avail /tmp 2>/dev/null | tail -1 | tr -dc '0-9')
idle_scratch_min=60
[ "${tmpfs_free_mb:-99999}" -lt 2048 ] && idle_scratch_min=5
for child in /tmp/opencode/*; do
  [ -d "$child" ] || continue
  recent=$(find "$child" -type f -mmin "-$idle_scratch_min" 2>/dev/null | wc -l)
  [ "$recent" -eq 0 ] || continue
  sz_kb=$(du -sk "$child" 2>/dev/null | cut -f1)
  if [ "${sz_kb:-0}" -gt 2097152 ] || [ "$idle_scratch_min" -eq 5 ]; then
    rm -rf "$child" && echo "reaped tmpfs scratch (${sz_kb}K, idle >${idle_scratch_min}min): $child"
  fi
done

# opencode WAL guard
wal="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db-wal"
if [ -f "$wal" ]; then
  walsz=$(stat -c %s "$wal" 2>/dev/null || echo 0)
  if [ "$walsz" -gt 2000000000 ]; then
    sqlite3 "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db" "PRAGMA busy_timeout=30000; PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1
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

# priority hygiene: agent-spawned builds historically inherit nice -4 from
# legacy terminal sessions and out-compete the desktop. Raise any nice<0
# build/agent process to 0 (raising nice is unprivileged). The deliberate
# compositor/terminal tweak (-12 kwin / -6 plasma) is left untouched.
for p in $(ps -eo nice,pid,comm | awk '$1 < 0 && $3 ~ /^(rustc|cargo|rust-lld|python|python3|lean|node|opencode|bun|cargo-clippy|clickhouse-serv)$/ {print $2}'); do
  renice -n 0 -p "$p" >/dev/null 2>&1 && echo "reniced $(ps -o comm= -p "$p" 2>/dev/null) (pid $p) -> 0"
done

echo "=== after ==="
df -h / | tail -1
} >> "$LOG" 2>&1
