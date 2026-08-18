#!/bin/bash
# vault-init — Initialize HashiCorp Vault and configure secrets engines
# Run once after installing Vault. Stores unseal key and root token locally.
set -e

export VAULT_ADDR='http://127.0.0.1:8200'

# Ensure Vault is running
echo ">> Checking Vault service..."
if ! systemctl is-active --quiet vault 2>/dev/null; then
    echo ">> Starting Vault service..."
    sudo systemctl start vault
    sleep 2
    for i in {1..10}; do
        if vault status -format=json 2>/dev/null | grep -q '"initialized"'; then
            break
        fi
        sleep 1
    done
fi

echo ">> Checking Vault status..."
# Check if already initialized by querying the API directly
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8200/v1/sys/init 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    INIT_STATE=$(curl -s http://127.0.0.1:8200/v1/sys/init 2>/dev/null | jq -r '.initialized')
    if [ "$INIT_STATE" = "true" ]; then
        echo ">> Vault already initialized."
        # Check if sealed
        SEALED=$(curl -s http://127.0.0.1:8200/v1/sys/seal-status 2>/dev/null | jq -r '.sealed')
        if [ "$SEALED" = "true" ] && [ -f ~/.vault-unseal.key ]; then
            echo ">> Unsealing..."
            vault operator unseal "$(cat ~/.vault-unseal.key)"
            echo ">> Vault unsealed."
        elif [ "$SEALED" = "false" ]; then
            echo ">> Vault is already unsealed."
        fi
        exit 0
    fi
fi

echo ">> Initializing Vault (1 key, threshold 1)..."
# Initialize directly via API to avoid token helper issues
INIT_RAW=$(curl -s -X PUT http://127.0.0.1:8200/v1/sys/init \
    -H "Content-Type: application/json" \
    -d '{"secret_shares":1,"secret_threshold":1}')

UNSEAL_KEY=$(echo "$INIT_RAW" | jq -r '.keys_base64[0]')
ROOT_TOKEN=$(echo "$INIT_RAW" | jq -r '.root_token')

if [ -z "$UNSEAL_KEY" ] || [ "$UNSEAL_KEY" = "null" ]; then
    echo ">> ERROR: Failed to initialize Vault."
    echo ">> Response: $INIT_RAW"
    exit 1
fi

echo ">> Unsealing Vault..."
vault operator unseal "$UNSEAL_KEY"

# Set root token for subsequent commands
export VAULT_TOKEN="$ROOT_TOKEN"

echo ">> Enabling secrets engines..."
vault secrets enable -path=secret kv-v2 2>/dev/null || true
vault secrets enable -path=ssh ssh 2>/dev/null || true

echo ">> Enabling userpass auth..."
vault auth enable userpass 2>/dev/null || true

echo ">> Storing unseal key..."
mkdir -p ~/.vault-secrets
chmod 700 ~/.vault-secrets
echo "$UNSEAL_KEY" > ~/.vault-secrets/unseal.key
chmod 600 ~/.vault-secrets/unseal.key

echo ">> Storing root token..."
echo "$ROOT_TOKEN" > ~/.vault-secrets/token
chmod 600 ~/.vault-secrets/token

# Also save to the vault config path
mkdir -p ~/.vault
chmod 700 ~/.vault

echo ""
echo "========================================="
echo "Vault initialized successfully!"
echo "========================================="
echo "Unseal key: ~/.vault-secrets/unseal.key"
echo "Root token: ~/.vault-secrets/token"
echo "UI: http://127.0.0.1:8200/ui"
echo ""
echo "Next: Run vault-store.sh to populate secrets."
