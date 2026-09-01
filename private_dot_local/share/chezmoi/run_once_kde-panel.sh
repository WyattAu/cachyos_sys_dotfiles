#!/bin/bash
# Run once: set up deterministic panel layout
# This script is deployed by chezmoi and runs on first apply only.
# It calls the main panel setup script which is idempotent.

# Headless hosts (servers) have no Plasma session — skip cleanly
# instead of failing chezmoi apply after the 30s plasmashell wait.
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && ! pgrep -x plasmashell >/dev/null 2>&1; then
    echo "No display session detected — skipping KDE panel setup"
    exit 0
fi

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
PANEL_SCRIPT="$CHEZMOI_DIR/scripts/kde-panel-setup.sh"

if [[ -f "$PANEL_SCRIPT" ]]; then
    exec "$PANEL_SCRIPT"
else
    echo "Panel setup script not found at $PANEL_SCRIPT"
    exit 1
fi
