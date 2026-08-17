#!/bin/bash
# Deterministic panel layout for all hosts
# Deploys Panel 23 with exact widget order:
#   Kickoff | Pager | Icon Tasks | Margins Separator | System Tray | Clock | Show Desktop
#
# This script runs once on first login via chezmoi run_once.
# It checks if the panel already exists before modifying anything.

set -e

PANEL_CONFIG="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
PANEL_SOURCE="$(dirname "$0")/../private_dot_config/plasma-org.kde.plasma.desktop-appletsrc"

# Skip if panel config already exists and has our panel (ID 23)
if [[ -f "$PANEL_CONFIG" ]] && grep -q "plugin=org.kde.panel" "$PANEL_CONFIG" 2>/dev/null; then
    echo "Panel already configured, skipping layout setup."
    exit 0
fi

echo ">> Setting up deterministic panel layout..."

# Wait for plasmashell to be ready
WAIT_COUNT=0
while ! qdbus6 org.kde.PlasmaShell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'panelIds.length' &>/dev/null; do
    if [[ $WAIT_COUNT -ge 30 ]]; then
        echo ">> plasmashell not ready after 30s, aborting."
        exit 1
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

echo ">> plasmashell ready, configuring panel..."

# Configure panel via D-Bus scripting API
qdbus6 org.kde.PlasmaShell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
// Panel configuration
var panelIds = PanelIds;
if (panelIds.length > 0) {
    var panel = panelById(panelIds[0]);
    if (panel) {
        // Panel properties
        panel.height = 42;
        panel.floating = true;
        panel.location = "bottom";
        panel.alignment = "left";
        panel.hiding = "none";

        // Widget order: Kickoff, Pager, Icon Tasks, Margins Separator, System Tray, Clock, Show Desktop
        var widgetOrder = [
            "org.kde.plasma.kickoff",
            "org.kde.plasma.pager",
            "org.kde.plasma.icontasks",
            "org.kde.plasma.marginsseparator",
            "org.kde.plasma.systemtray",
            "org.kde.plasma.digitalclock",
            "org.kde.plasma.showdesktop"
        ];

        // Add missing widgets
        for (var i = 0; i < widgetOrder.length; i++) {
            var found = false;
            for (var j = 0; j < panel.widgetIds.length; j++) {
                var w = panel.widgetById(panel.widgetIds[j]);
                if (w && w.type === widgetOrder[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                panel.addWidget(widgetOrder[i]);
            }
        }

        "Panel configured successfully";
    } else {
        "Panel not found";
    }
} else {
    "No panels found";
}
' 2>/dev/null || true

# Configure widget-specific settings
qdbus6 org.kde.PlasmaShell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var panelIds = PanelIds;
if (panelIds.length > 0) {
    var panel = panelById(panelIds[0]);
    if (panel) {
        // Configure Kickoff
        for (var i = 0; i < panel.widgetIds.length; i++) {
            var w = panel.widgetById(panel.widgetIds[i]);
            if (w && w.type === "org.kde.plasma.kickoff") {
                w.writeConfig("icon", "org.cachyos.hello");
                w.writeConfig("globalSearch", true);
            }
            // Configure Digital Clock
            if (w && w.type === "org.kde.plasma.digitalclock") {
                w.writeConfig("showDate", true);
                w.writeConfig("dateFormat", "isoDate");
            }
            // Configure Icon Tasks
            if (w && w.type === "org.kde.plasma.icontasks") {
                w.writeConfig("launchers", "applications:systemsettings.desktop,preferred://filemanager,preferred://browser");
            }
        }
        "Widget settings configured";
    }
}
' 2>/dev/null || true

echo ">> Panel layout setup complete."
echo ">> A logout/login may be required for full effect."
