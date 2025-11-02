#!/usr/bin/env bash

set -euo pipefail
# clean-zsh-p10k-system.sh
# System-wide install of Zsh + Oh My Zsh + Powerlevel10k
# Usage: sudo bash clean-zsh-p10k-system.sh

# Ensure sudo session is active
sudo -v

echo "Starting system-wide clean installation of Zsh + Oh My Zsh + Powerlevel10k..."
# 0) Change back to bash
chsh -s /bin/bash

# 1) Remove old zsh configs & Oh My Zsh (system-wide defaults)
[[ -d "/usr/share/oh-my-zsh" ]] && rm -rf "/usr/share/oh-my-zsh"
[[ -f "/etc/skel/.zshrc" ]] && rm -f "/etc/skel/.zshrc"
[[ -f "/etc/skel/.p10k.zsh" ]] && rm -f "/etc/skel/.p10k.zsh"

# 2) Remove old zsh package
apt remove -y zsh || true
apt purge -y zsh || true

# 3) Update & install fresh zsh + tools
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "zsh not found after install — aborting."; exit 1; }

# 4) Install Oh My Zsh system-wide
OMZ_DIR="/usr/share/oh-my-zsh"
export RUNZSH=no
export CHSH=no
if [[ ! -d "$OMZ_DIR" ]]; then
    echo "Installing Oh My Zsh system-wide..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    mv "$HOME/.oh-my-zsh" "$OMZ_DIR"
fi

# 5) Install Powerlevel10k system-wide
P10K_DIR="$OMZ_DIR/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 6) Set global default .zshrc for new users
cat > /etc/skel/.zshrc <<'EOF'
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF

# 7) Update all existing users to Zsh
echo "Setting Zsh as default shell for all users..."
for u in $(awk -F: '{ if ($7 !~ /nologin|false|/bin/false/) print $1 }' /etc/passwd); do
    chsh -s /usr/bin/zsh "$u" || echo "Failed to change shell for user $u"
done

# 8) Force default shell for current session
chsh -s /usr/bin/zsh

echo "System-wide Zsh + Oh My Zsh + Powerlevel10k installation complete!"
echo "New users will start with Zsh by default."
echo "Existing users should log out and back in to use Zsh."
