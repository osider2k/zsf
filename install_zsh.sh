#!/usr/bin/env bash
set -euo pipefail
# clean-zsh-p10k-system.sh
# Clean system-wide install of zsh + Oh My Zsh + Powerlevel10k
# Usage: curl -fsSL <RAW_URL> | sudo bash

# Ensure sudo session is active
sudo -v

echo "Starting system-wide clean installation of Zsh + Oh My Zsh + Powerlevel10k..."

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
export RUNZSH=no
export CHSH=no
OMZ_DIR="/usr/share/oh-my-zsh"
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

# 6) Set global default .zshrc (for new users)
cat > /etc/skel/.zshrc <<'EOF'
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF

echo "System-wide Zsh + Oh My Zsh + Powerlevel10k installation complete!"
echo "New users will start with Zsh by default. Existing users may need to log out and back in."

# 7) Force default shell for current session
chsh -s /usr/bin/zsh
