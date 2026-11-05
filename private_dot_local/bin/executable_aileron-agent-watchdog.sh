#!/usr/bin/env bash
# aileron-agent-watchdog.sh -- restart aileron-agent.service when its MCP
# TCP bridge on 127.0.0.1:9543 stops answering while the unit claims active.
#
# Caught in the wild (2026-11-05): the daemon zombie state — process alive,
# 12 threads, 13 MB RSS, zero WebKitWebProcess children, TCP listener gone,
# no logs for 7.5 h after a burst of ~40 session connects. Restart=on-failure
# cannot see this: the process never exits.
#
# Probe: a real MCP initialize handshake over the line-JSON TCP protocol.
# A bare TCP connect is not enough (the listener can accept while dispatch
# is wedged); a full handshake catches both.
#
# Flap guard: restarts only after 2 consecutive failures; a counter file
# tracks consecutive failures, cleared on first success.
set -u

UNIT="aileron-agent.service"
STATE="/home/wyatt/.local/state/aileron-agent-watchdog.count"
LOG="/home/wyatt/.local/share/aileron-agent-watchdog.log"
PORT="${AILERON_AGENT_MCP_PORT:-9543}"

probe() {
    # 1) socket connect
    if ! exec 3<>"/dev/tcp/127.0.0.1/$PORT" 2>/dev/null; then
        return 1
    fi
    # 2) MCP initialize handshake, 6 s budget
    printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"agent-watchdog","version":"1"}}}\n' >&3
    local reply=""
    IFS= read -r -t 6 -u 3 reply || { exec 3>&- 3<&-; return 1; }
    exec 3>&- 3<&-
    [[ "$reply" == *'"result"'* ]]
}

if probe; then
    rm -f "$STATE"
    exit 0
fi

# Unit not active? Restart=on-failure owns exits; nothing to watch here.
if [ "$(systemctl --user is-active "$UNIT" 2>/dev/null)" != "active" ]; then
    rm -f "$STATE"
    exit 0
fi

COUNT=$(( $(cat "$STATE" 2>/dev/null || echo 0) + 1 ))
echo "$COUNT" > "$STATE"
echo "$(date '+%F %T') watchdog: bridge down (consecutive check $COUNT)" >> "$LOG"

if [ "$COUNT" -ge 2 ]; then
    # Flap guard: if we already restarted within the last 10 minutes and the
    # bridge is STILL down (e.g. port held by another process), restarting
    # again changes nothing - log and stand off instead of looping.
    LAST="/home/wyatt/.local/state/aileron-agent-watchdog.lastrestart"
    NOW=$(date +%s)
    PREV=$(cat "$LAST" 2>/dev/null || echo 0)
    if [ $((NOW - PREV)) -lt 600 ]; then
        echo "$(date '+%F %T') watchdog: bridge still down <10min after last restart - standing off" >> "$LOG"
        exit 0
    fi
    echo "$NOW" > "$LAST"
    echo "$(date '+%F %T') watchdog: restarting $UNIT" >> "$LOG"
    rm -f "$STATE"
    systemctl --user restart "$UNIT"
fi
