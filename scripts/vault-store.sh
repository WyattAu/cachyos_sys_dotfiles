#!/bin/bash
# vault-store — Store common secrets in Vault
# Run after vault-init. Reads existing secrets from system and stores them.
set -e

export VAULT_ADDR='http://127.0.0.1:8200'

if [ ! -f ~/.vault-secrets/token ]; then
    echo "ERROR: ~/.vault-secrets/token not found. Run vault-init first."
    exit 1
fi

export VAULT_TOKEN=$(cat ~/.vault-secrets/token)

echo ">> Storing SSH keys..."
if [ -f ~/.ssh/id_ed25519 ]; then
    vault kv put secret/ssh/ed25519 \
        private_key="$(cat ~/.ssh/id_ed25519)" \
        public_key="$(cat ~/.ssh/id_ed25519.pub)" 2>/dev/null
    echo "  ✓ SSH ed25519 key stored"
else
    echo "  ⚠ No SSH ed25519 key found"
fi

echo ">> Storing GitHub token..."
# Prefer `gh auth token` (works with keyring/hosts.yml storage);
# fall back to raw hosts.yml grep for non-interactive contexts.
GH_TOKEN=""
if command -v gh &>/dev/null; then
    GH_TOKEN=$(gh auth token 2>/dev/null || true)
fi
if [ -z "$GH_TOKEN" ] && [ -f ~/.config/gh/hosts.yml ]; then
    GH_TOKEN=$(grep oauth_token ~/.config/gh/hosts.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
fi
if [ -n "$GH_TOKEN" ]; then
    vault kv put secret/github/token \
        token="$GH_TOKEN" 2>/dev/null
    echo "  ✓ GitHub token stored"
else
    echo "  ⚠ No GitHub token — run: gh auth login -h github.com"
    echo "    then re-run vault-store.sh"
fi

echo ">> Storing OCIS credentials..."
if [ -f ~/.config/ownCloud/owncloud.cfg ]; then
    echo "  ⚠ OCIS credentials found but not auto-extracted (interactive setup required)"
    echo "  Run manually: vault kv put secret/ocis/credentials url=https://ocis.wyattau.com username=YOUR_USER password=YOUR_PASS"
else
    echo "  ⚠ OCIS config not found"
fi

echo ">> Storing ProtonVPN info..."
echo "  ℹ ProtonVPN uses gnome-keyring for credentials (not stored in Vault)"
echo "  Vault stores the config reference only"
vault kv put secret/vpn/proton \
    protocol="wireguard" \
    split_tunneling="true" \
    kill_switch="true" 2>/dev/null
echo "  ✓ ProtonVPN config stored"

echo ">> Storing Nix access tokens..."
if [ -f ~/.config/nix/nix.conf ]; then
    echo "  ℹ Nix access tokens are optional (for private caches)"
fi

echo ""
echo ">> Vault secrets populated."
echo ">> View with: vault kv list secret/"
echo ">> View SSH:  vault kv get -field=public_key secret/ssh/ed25519"
