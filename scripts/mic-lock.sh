#!/usr/bin/env bash
# mic-lock: keep the internal digital mic volume pinned while Element
# records. Chromium's WebRTC AGC2 ("input volume controller") rewrites
# the OS mic volume every few seconds during calls, ignoring
# --disable-features=WebRtcAllowInputVolumeAdjustment on Electron 43.
# This pins the volume ONLY while an Element source-output exists;
# outside calls you can adjust the mic freely.
#
# Change the pinned level:  ~/.config/mic-lock.conf  ->  PIN=65

PIN="${PIN:-70}"
CONF="$HOME/.config/mic-lock.conf"
[ -f "$CONF" ] && source "$CONF"
PIN="${PIN:-70}"

SRC="alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source"

while true; do
    if pactl list source-outputs short 2>/dev/null | grep -qi element; then
        cur="$(pactl get-source-volume "$SRC" 2>/dev/null | grep -o '[0-9]*%' | head -n1)"
        if [ -n "$cur" ] && [ "$cur" != "${PIN}%" ]; then
            pactl set-source-volume "$SRC" "${PIN}%" 2>/dev/null
        fi
    fi
    sleep 0.4
done
