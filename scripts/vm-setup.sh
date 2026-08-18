#!/bin/bash
# vm-setup — One-time setup for VictoriaMetrics + Telegram alerts
# Run this after vault-init.sh to configure monitoring alerts

set -e

echo ">> VictoriaMetrics + Telegram Alert Setup"
echo ""

# Check if VictoriaMetrics is available
if ! command -v victoria-metrics &>/dev/null; then
    echo ">> ERROR: VictoriaMetrics not installed."
    echo ">> Run sys-sync first to install it."
    exit 1
fi

# Check if node_exporter is available
if ! command -v prometheus-node-exporter &>/dev/null; then
    echo ">> ERROR: prometheus-node-exporter not installed."
    echo ">> Run sys-sync first to install it."
    exit 1
fi

echo ">> Telegram Bot Setup"
echo ">> =================="
echo ""
echo ">> To receive alerts, you need a Telegram bot:"
echo ">> 1. Open Telegram and search for @BotFather"
echo ">> 2. Send /newbot"
echo ">> 3. Follow the prompts to create your bot"
echo ">> 4. Copy the bot token"
echo ""

read -p ">> Enter your Telegram bot token (or press Enter to skip): " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo ">> Skipping Telegram setup."
    echo ">> You can configure it later by editing /etc/alertmanager/alertmanager.yml"
    exit 0
fi

echo ""
echo ">> To get your chat_id:"
echo ">> 1. Send any message to your bot"
echo ">> 2. Open this URL in a browser:"
echo ">>    https://api.telegram.org/bot${BOT_TOKEN}/getUpdates"
echo ">> 3. Find 'chat':{'id':XXXXXXX} in the response"
echo ""

read -p ">> Enter your Telegram chat_id: " CHAT_ID

if [ -z "$CHAT_ID" ]; then
    echo ">> Skipping Telegram setup."
    exit 0
fi

# Store bot token securely
echo "$BOT_TOKEN" | sudo tee /etc/alertmanager/telegram-token > /dev/null
sudo chmod 600 /etc/alertmanager/telegram-token

# Update alertmanager config with real chat_id
sudo sed -i "s/chat_id: 0/chat_id: $CHAT_ID/" /etc/alertmanager/alertmanager.yml

echo ">> Telegram alerts configured!"
echo ">> Bot token stored at /etc/alertmanager/telegram-token"
echo ">> Chat ID set to $CHAT_ID"
echo ""

# Start monitoring
echo ">> Starting VictoriaMetrics..."
sudo systemctl start victoriametrics prometheus-node-exporter 2>/dev/null || true

echo ">> Starting alertmanager..."
sudo systemctl start alertmanager 2>/dev/null || true

echo ""
echo ">> Monitoring active!"
echo ">> VictoriaMetrics: http://localhost:8428"
echo ">> Node metrics:    http://localhost:9100/metrics"
echo ">> Alertmanager:    http://localhost:9093"
echo ""
echo ">> Test with: sys-monitor status"
