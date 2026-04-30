#!/bin/bash
set -e
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}>> System Bootstrap${NC}"

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

CHEZMOI_DIR="/home/$REAL_USER/.local/share/chezmoi"
ANSIBLE_DIR="$CHEZMOI_DIR/ansible"

# 3. PRE-FLIGHT: Install prerequisites
echo -e "${BLUE}>> Checking prerequisites...${NC}"

install_if_missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo -e "${YELLOW}>> Installing $1...${NC}"
    sudo pacman -S --noconfirm "$1"
  fi
}

# Required for Ansible and the playbook
install_if_missing git
install_if_missing ansible
install_if_missing base-devel

# AUR helper (required for AUR packages in playbook)
if ! command -v paru >/dev/null 2>&1; then
  echo -e "${YELLOW}>> Installing paru (AUR helper)...${NC}"
  sudo pacman -S --noconfirm git
  TMPDIR=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru.git "$TMPDIR/paru" || {
    echo "Error: Failed to clone paru"
    rm -rf "$TMPDIR"
    exit 1
  }
  (cd "$TMPDIR/paru" && makepkg -si --noconfirm) || {
    echo "Error: Failed to build paru"
    rm -rf "$TMPDIR"
    exit 1
  }
  rm -rf "$TMPDIR"
fi

# Verify repo is cloned
if [ ! -f "$ANSIBLE_DIR/local.yml" ]; then
  echo -e "${YELLOW}>> Repo not found. Cloning from GitHub...${NC}"
  mkdir -p "$CHEZMOI_DIR"
  git clone https://github.com/WyattAu/cachyos_sys_dotfiles.git "$CHEZMOI_DIR" || {
    echo "Error: Failed to clone dotfiles repo"
    exit 1
  }
fi

# 4. GENERATE SSH KEY (if missing)
SSH_KEY="/home/$REAL_USER/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo -e "${YELLOW}>> Generating SSH key (ed25519)...${NC}"
  mkdir -p "/home/$REAL_USER/.ssh"
  ssh-keygen -t ed25519 -C "wyatt@$(hostname)" -f "$SSH_KEY" -N ""
  chown -R "$REAL_USER:$REAL_USER" "/home/$REAL_USER/.ssh"
  chmod 700 "/home/$REAL_USER/.ssh"
  chmod 600 "$SSH_KEY" "$SSH_KEY.pub"
  echo -e "${YELLOW}>> NEW SSH KEY generated. Add public key to GitHub and TrueNAS:${NC}"
  cat "$SSH_KEY.pub"
fi

# 5. INSTALL ANSIBLE COLLECTIONS
echo -e "${BLUE}>> Installing Ansible Collections...${NC}"
ansible-galaxy collection install community.general kewlfft.aur community.docker

# 6. RUN PLAYBOOK
echo -e "${BLUE}>> Running Ansible Playbook...${NC}"
cd "$ANSIBLE_DIR"
# -i localhost, tells Ansible this is an inline host list (trailing comma is intentional)
# Without it, Ansible auto-discovers local.yml and host_vars/ as inventory sources
ansible-playbook local.yml -i localhost, --extra-vars "user=$REAL_USER"

# 7. APPLY DOTFILES (as real user, not root)
echo -e "${BLUE}>> Applying user dotfiles...${NC}"
if command -v chezmoi >/dev/null 2>&1; then
  su -c "chezmoi apply --force" "$REAL_USER"
else
  echo -e "${YELLOW}>> chezmoi not found — skipping dotfile apply. Run 'chezmoi apply --force' manually.${NC}"
fi

echo -e "${GREEN}>> System Provisioning Complete.${NC}"
