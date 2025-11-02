#!/usr/bin/env bash
set -euo pipefail
# install_zsh_systemwide.sh
# System-wide Zsh + Oh My Zsh + Powerlevel10k installation
# Makes Zsh the default shell for all users
# Usage: curl -fsSL <RAW_URL> | sudo bash

echo "=== System-wide Zsh + Oh My Zsh + Powerlevel10k Installation ==="

sudo -v

# 1) Remove any old system installations
sudo rm -rf /usr/share/oh-my-zsh || true
sudo rm -f /etc/skel/.zshrc /etc/skel/.p10k.zsh || true

# 2) Install packages
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "❌ zsh not found after install"; exit 1; }

# 3) Install Oh My Zsh system-wide
echo "Installing Oh My Zsh..."
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

# 4) Configure default .zshrc for all users
sudo cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sudo sed -i 's|ZSH=.*|ZSH=/usr/share/oh-my-zsh|' /etc/skel/.zshrc

# 5) Install Powerlevel10k theme
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

sudo sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /etc/skel/.zshrc

# 6) Copy to existing users if needed
for uhome in /home/*; do
    if [[ -d "$uhome" && ! -f "$uhome/.zshrc" ]]; then
        sudo cp /etc/skel/.zshrc "$uhome/.zshrc"
        sudo chown "$(basename "$uhome")":"$(basename "$uhome")" "$uhome/.zshrc"
    fi
done

# 7) Set /usr/bin/zsh as default shell globally
echo "Setting Zsh as default shell for all users..."
if ! grep -q "/usr/bin/zsh" /etc/shells; then
    echo "/usr/bin/zsh" | sudo tee -a /etc/shells > /dev/null
fi

# Update all users’ login shells
sudo sed -i 's|/bin/bash|/usr/bin/zsh|g' /etc/passwd

echo ""
echo "✅ System-wide Zsh installation complete!"
echo "All users will now start in Zsh by default."
echo "Type 'p10k configure' to run the Powerlevel10k setup"
echo "Shell path: $ZSH_BIN"
