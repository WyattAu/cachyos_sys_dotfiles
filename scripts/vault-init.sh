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
    # Wait for Vault to be ready
    for i in {1..10}; do
        if vault status -format=json 2>/dev/null | grep -q '"initialized"'; then
            break
        fi
        sleep 1
    done
fi

echo ">> Checking Vault status..."
if vault status -format=json 2>/dev/null | grep -q '"initialized":true'; then
    echo ">> Vault already initialized."
    echo ">> Unsealing..."
    if [ -f ~/.vault/unseal.key ]; then
        vault operator unseal "$(cat ~/.vault/unseal.key)"
        echo ">> Vault unsealed."
    else
        echo ">> ERROR: Vault initialized but ~/.vault/unseal.key not found."
        echo ">> You'll need to unseal manually or re-initialize."
        exit 1
    fi
    exit 0
fi

echo ">> Initializing Vault (1 key, threshold 1)..."
INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)

UNSEAL_KEY=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')

echo ">> Unsealing Vault..."
vault operator unseal "$UNSEAL_KEY"

echo ">> Enabling secrets engines..."
vault secrets enable -path=secret kv-v2 2>/dev/null || true
vault secrets enable -path=ssh ssh 2>/dev/null || true

echo ">> Enabling userpass auth (optional, for non-root access)..."
vault auth enable userpass 2>/dev/null || true

echo ">> Storing unseal key..."
mkdir -p ~/.vault
chmod 700 ~/.vault
echo "$UNSEAL_KEY" > ~/.vault/unseal.key
chmod 600 ~/.vault/unseal.key

echo ">> Storing root token..."
echo "$ROOT_TOKEN" > ~/.vault/token
chmod 600 ~/.vault/token

echo ""
echo "========================================="
echo "Vault initialized successfully!"
echo "========================================="
echo "Unseal key: ~/.vault/unseal.key"
echo "Root token: ~/.vault/token"
echo "UI: http://127.0.0.1:8200/ui"
echo ""
echo "Next: Run vault-store.sh to populate secrets."
