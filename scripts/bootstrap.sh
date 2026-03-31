#!/bin/bash
set -e
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}>> CachyOS Infrastructure Bootstrap${NC}"

# 1. FORCE ROOT EXECUTION
if [ "$EUID" -ne 0 ]; then
  echo -e "${BLUE}>> Requesting Sudo (Swipe Finger now)...${NC}"
  sudo "$0" "$@"
  exit
fi

# 2. DETECT REAL USER
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  echo "Error: Could not detect actual user. Run via 'sudo ./bootstrap.sh'"
  exit 1
fi

# 3. INSTALL COLLECTIONS (For Root)
echo -e "${BLUE}>> Installing Ansible Collections...${NC}"
ansible-galaxy collection install community.general kewlfft.aur

# 4. RUN PLAYBOOK
echo -e "${BLUE}>> Running Ansible Playbook...${NC}"
cd "/home/$REAL_USER/.local/share/chezmoi/ansible"
# -i localhost, tells Ansible this is an inline host list (trailing comma is intentional)
# Without it, Ansible auto-discovers local.yml and host_vars/ as inventory sources
ansible-playbook local.yml -i localhost, --extra-vars "user=$REAL_USER"

echo -e "${GREEN}>> System Provisioning Complete.${NC}"
