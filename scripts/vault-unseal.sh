#!/bin/bash
# vault-unseal — Auto-unseal Vault on boot
# Called by vault-unseal.service after vault.service starts
set -e

export VAULT_ADDR='http://127.0.0.1:8200'

# Wait for Vault to be ready
for i in {1..10}; do
    if curl -s http://127.0.0.1:8200/v1/sys/seal-status 2>/dev/null | grep -q '"sealed"'; then
        break
    fi
    sleep 1
done

# Check if sealed
SEALED=$(curl -s http://127.0.0.1:8200/v1/sys/seal-status 2>/dev/null | jq -r '.sealed')

if [ "$SEALED" = "true" ]; then
    if [ -f /home/wyatt/.vault-secrets/unseal.key ]; then
        vault operator unseal "$(cat /home/wyatt/.vault-secrets/unseal.key)"
        echo "Vault unsealed."
    else
        echo "ERROR: Unseal key not found."
        exit 1
    fi
else
    echo "Vault is already unsealed."
fi
