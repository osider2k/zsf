#!/usr/bin/env bash
set -euo pipefail
# install_zsh_systemwide_safe.sh
# Safe system-wide Zsh + Oh My Zsh + Powerlevel10k installation

echo "=== System-wide Zsh + Oh My Zsh + Powerlevel10k Installation ==="

# Ensure sudo
sudo -v

# 1) Remove old Oh My Zsh from /usr/share
sudo rm -rf /usr/share/oh-my-zsh || true
sudo rm -f /etc/skel/.zshrc /etc/skel/.p10k.zsh || true

# 2) Install required packages
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y --no-install-recommends zsh git curl ca-certificates

# Locate zsh
ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "❌ zsh not found after install"; exit 1; }

# 3) Install Oh My Zsh system-wide
echo "Installing Oh My Zsh..."
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

# 4) Configure default .zshrc for new users
sudo cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sudo sed -i "s|ZSH=.*|ZSH=/usr/share/oh-my-zsh|" /etc/skel/.zshrc

# 5) Install Powerlevel10k theme
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi
sudo sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /etc/skel/.zshrc

# 6) Copy .zshrc to existing human users if missing
for uhome in /home/*; do
    if [[ -d "$uhome" ]]; then
        username=$(basename "$uhome")
        zshrc="$uhome/.zshrc"
        if [[ ! -f "$zshrc" ]]; then
            sudo cp /etc/skel/.zshrc "$zshrc"
            sudo chown "$username":"$username" "$zshrc"
        else
            # Backup existing .zshrc if you want to preserve it
            sudo cp "$zshrc" "$zshrc.backup"
            echo "Existing .zshrc backed up: $zshrc.backup"
        fi
    fi
done

# 7) Add Zsh to /etc/shells if missing
if ! grep -q "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi

# 8) Set Zsh as default shell for human users only
for uhome in /home/*; do
    if [[ -d "$uhome" ]]; then
        username=$(basename "$uhome")
        sudo chsh -s "$ZSH_BIN" "$username" || true
    fi
done

echo ""
echo "✅ System-wide Zsh installation complete!"
echo "All human users will now start in Zsh by default."
echo "Type 'p10k configure' in your shell to run the Powerlevel10k setup."
echo "Shell path: $ZSH_BIN"
