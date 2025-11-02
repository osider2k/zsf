#!/usr/bin/env bash
set -euo pipefail
# install_zsh.sh
# System-wide clean install of Zsh + Oh My Zsh + Powerlevel10k (no chsh)
# Usage: curl -fsSL <RAW_URL> | bash

echo "Starting system-wide clean installation of Zsh + Oh My Zsh + Powerlevel10k..."
sudo -v

# 1) Clean up old installations
sudo rm -rf /usr/share/oh-my-zsh || true
sudo rm -f /etc/skel/.zshrc /etc/skel/.p10k.zsh || true
sudo rm -f /var/cache/apt/pkgcache.bin /var/cache/apt/srcpkgcache.bin || true

# 2) Reinstall zsh + dependencies
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "Error: zsh not found after install"; exit 1; }

# 3) Install Oh My Zsh (system-wide)
echo "Installing Oh My Zsh..."
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

# 4) Copy default configs to /etc/skel (for new users)
sudo cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sudo sed -i 's|ZSH=.*|ZSH=/usr/share/oh-my-zsh|' /etc/skel/.zshrc

# 5) Install Powerlevel10k theme system-wide
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k theme..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 6) Set default theme in skel config
sudo sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /etc/skel/.zshrc

# 7) Copy configs to existing users if not present
for uhome in /home/*; do
    if [[ -d "$uhome" && ! -f "$uhome/.zshrc" ]]; then
        sudo cp /etc/skel/.zshrc "$uhome/.zshrc"
        sudo chown "$(basename "$uhome")":"$(basename "$uhome")" "$uhome/.zshrc"
    fi
done

# 8) Inform user how to use Zsh
echo ""
echo "✅ Installation complete!"
echo "To start using Zsh now, run:"
echo ""
echo "   zsh"
echo ""
echo "(Default shell not changed — this avoids PAM authentication errors)"
echo "If you still want to make it permanent later, run: sudo chsh -s /usr/bin/zsh <username>"
