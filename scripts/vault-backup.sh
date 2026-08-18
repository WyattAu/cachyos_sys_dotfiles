#!/bin/bash
# vault-backup — Copy Vault recovery material into pika-backup scope
#
# ~/.vault-secrets/ holds the unseal key and root token. If the disk dies,
# Vault contents are unrecoverable without them. This script mirrors them
# to ~/Library/Vault/ which IS covered by pika-backup → TrueNAS.
#
# Threat-model note: this places unseal material on your own NAS, protected
# by your NAS access controls. For higher assurance, also record the unseal
# key offline (password manager / printed sheet) — see README 'Secrets Recovery'.

set -e

SRC=~/.vault-secrets
DEST=~/Library/Vault

if [ ! -f "$SRC/unseal.key" ]; then
    echo "ERROR: $SRC/unseal.key not found. Run vault-init.sh first."
    exit 1
fi

mkdir -p "$DEST"
chmod 700 "$DEST"

# Copy unseal key + token + a marker with hostname/date
install -m 600 "$SRC/unseal.key" "$DEST/unseal.key"
[ -f "$SRC/token" ] && install -m 600 "$SRC/token" "$DEST/token"

cat > "$DEST/README.txt" << EOF
Vault recovery material for $(hostname)
Generated: $(date)
Vault addr: http://127.0.0.1:8200

Restore procedure:
  1. Start vault:      sudo systemctl start vault
  2. Unseal:           VAULT_ADDR=http://127.0.0.1:8200 vault operator unseal $(cat "$DEST/unseal.key" >/dev/null && echo '<contents of unseal.key>')
  3. Export token:     export VAULT_TOKEN=$(cat "$DEST/token" >/dev/null 2>&1 && echo '<contents of token>')
  4. Verify:           vault kv list secret/

Data itself lives in /opt/vault/data (or VAR path) — restore that
directory from system backups if the disk was replaced.
EOF
chmod 600 "$DEST/README.txt"

echo ">> Recovery material mirrored to $DEST (pika-backup scope)"
echo ">> Files: unseal.key, token, README.txt"
echo ">> Next pika-backup run will include them."
