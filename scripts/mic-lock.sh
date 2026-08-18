#!/bin/bash
# mic-lock — Control mic-volume auto-adjust protection
#
# Blocks apps with AGC (browsers, Discord, Zoom, Teams...) from changing
# microphone volume. Targeted list — your mixers (pavucontrol, KDE audio
# widget, wpctl) keep working normally.
#
# Usage:
#   mic-lock                  show status + current mic volume
#   mic-lock on               re-apply protection (same as sys-sync)
#   mic-lock off              temporarily disable protection
#   mic-lock set 80%          set mic volume

set -e

CONF="$HOME/.config/pipewire/pipewire-pulse.conf.d/51-block-source-volume.conf"
SRC="$HOME/.local/share/chezmoi/private_dot_config/pipewire/pipewire-pulse.conf.d/51-block-source-volume.conf"

restart_pulse() {
    systemctl --user restart pipewire-pulse.service 2>/dev/null || true
    echo ">> pipewire-pulse restarted — audio apps with live calls may need"
    echo ">> a full restart (Electron apps like Element/Discord reconnect poorly)."
}

case "${1:-status}" in
    on)
        mkdir -p "$(dirname "$CONF")"
        install -m 644 "$SRC" "$CONF"
        restart_pulse
        echo ">> Mic auto-adjust protection ON (apps cannot change mic volume)"
        echo ">> Note: next sys-sync also re-enables this automatically."
        ;;
    off)
        rm -f "$CONF"
        restart_pulse
        echo ">> Mic auto-adjust protection OFF (apps can change mic volume)"
        echo ">> Temporary — sys-sync or 'mic-lock on' restores it."
        ;;
    set)
        VOL="${2:?usage: mic-lock set 80%}"
        wpctl set-volume --limit 1.0 "$VOL" @DEFAULT_AUDIO_SOURCE@
        wpctl get-volume @DEFAULT_AUDIO_SOURCE@
        ;;
    status)
        if [ -f "$CONF" ]; then
            echo ">> Protection: ON"
        else
            echo ">> Protection: OFF"
        fi
        wpctl get-volume @DEFAULT_AUDIO_SOURCE@ || true
        ;;
    *)
        echo "Usage: mic-lock [on|off|set VOL%|status]"
        exit 1
        ;;
esac
