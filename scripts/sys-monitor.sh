#!/bin/bash
# sys-monitor — Start/stop monitoring services on demand
# Usage: sys-monitor start|stop|status

set -e

case "$1" in
    start)
        echo ">> Starting monitoring..."
        sudo systemctl start victoriametrics node_exporter 2>/dev/null || true
        echo "  VictoriaMetrics: http://localhost:8428"
        echo "  Node metrics:    http://localhost:9100/metrics"
        ;;
    stop)
        echo ">> Stopping monitoring..."
        sudo systemctl stop victoriametrics node_exporter 2>/dev/null || true
        echo "  All monitoring stopped."
        ;;
    status)
        echo ">> Monitoring status:"
        for svc in victoriametrics node_exporter vault; do
            STATUS=$(systemctl is-active $svc 2>/dev/null || echo "inactive")
            if [ "$STATUS" = "active" ]; then
                echo "  ✓ $svc (active)"
            else
                echo "  ○ $svc ($STATUS)"
            fi
        done
        ;;
    *)
        echo "Usage: sys-monitor start|stop|status"
        exit 1
        ;;
esac
