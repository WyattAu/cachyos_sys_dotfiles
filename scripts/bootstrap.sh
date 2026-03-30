#!/bin/bash
set -e
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}>> CachyOS Infrastructure Bootstrap${NC}"

# 1. FORCE ROOT EXECUTION
if [ "$EUID" -ne 0 ]; then
  echo -e "${BLUE}>> Requesting Sudo...${NC}"
  sudo "$0" "$@"
  exit
fi

# 2. DETECT REAL USER
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  echo "Error: Could not detect actual user."
  exit 1
fi

# 3. ENSURE AUR HELPER EXISTS (Critical for your Playbook)
if ! command -v paru &> /dev/null; then
    echo -e "${BLUE}>> Paru not found. Installing...${NC}"
    pacman -S --needed --noconfirm base-devel
    # Temporary clone and build as real user
    sudo -u "$REAL_USER" bash -c "cd /tmp && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm"
fi

# 4. INSTALL COLLECTIONS
# We install them globally so Ansible always finds them regardless of 'become'
echo -e "${BLUE}>> Ensuring Ansible Collections...${NC}"
ansible-galaxy collection install community.general kewlfft.aur --upgrade

# 5. RUN PLAYBOOK
echo -e "${BLUE}>> Running Ansible Playbook...${NC}"
# Use the full path to avoid any 'cd' confusion
PLAYBOOK_PATH="/home/$REAL_USER/.local/share/chezmoi/ansible/local.yml"
# We pass the user variable and force the home directory fact
sudo -u "$REAL_USER" ansible-playbook "$PLAYBOOK_PATH" --become --ask-become-pass \
    --extra-vars "user=$REAL_USER"

echo -e "${GREEN}>> System Provisioning Complete.${NC}"