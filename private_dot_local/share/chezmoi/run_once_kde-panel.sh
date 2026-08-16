#!/bin/bash
# Run once: set up deterministic panel layout
# This script is deployed by chezmoi and runs on first apply only.
# It calls the main panel setup script which is idempotent.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PANEL_SCRIPT="$SCRIPT_DIR/../../scripts/kde-panel-setup.sh"

if [[ -f "$PANEL_SCRIPT" ]]; then
    exec "$PANEL_SCRIPT"
else
    echo "Panel setup script not found at $PANEL_SCRIPT"
    exit 1
fi
