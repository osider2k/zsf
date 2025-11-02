#!/usr/bin/env bash
set -euo pipefail
# install_zsh_systemwide_ready_p10k.sh
# System-wide Zsh + Oh My Zsh + Powerlevel10k with ready-to-use p10k

echo "=== System-wide Zsh + Oh My Zsh + Powerlevel10k Installation ==="

sudo -v

# 1) Remove old installations
sudo rm -rf /usr/share/oh-my-zsh || true
sudo rm -f /etc/skel/.zshrc /etc/skel/.p10k.zsh || true

# 2) Install packages
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y --no-install-recommends zsh git curl ca-certificates

# 3) Locate Zsh
ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "❌ zsh not found after install"; exit 1; }

# 4) Install Oh My Zsh system-wide
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

# 5) Configure default .zshrc for new users
sudo cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sudo sed -i "s|ZSH=.*|ZSH=/usr/share/oh-my-zsh|" /etc/skel/.zshrc

# 6) Install Powerlevel10k
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi
sudo sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /etc/skel/.zshrc

# 7) Ensure Powerlevel10k functions are available immediately for new users
sudo tee -a /etc/skel/.zshrc > /dev/null <<'EOF'

# Load Powerlevel10k functions immediately
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi
EOF

# 8) Copy .zshrc to existing human users, backup if exists
for uhome in /home/*; do
    if [[ -d "$uhome" ]]; then
        username=$(basename "$uhome")
        zshrc="$uhome/.zshrc"
        if [[ -f "$zshrc" ]]; then
            sudo cp "$zshrc" "$zshrc.backup"
            echo "Backed up existing .zshrc: $zshrc.backup"
        fi
        sudo cp /etc/skel/.zshrc "$zshrc"
        sudo chown "$username":"$username" "$zshrc"
    fi
done

# 9) Add Zsh to /etc/shells if missing
if ! grep -q "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi

# 10) Set Zsh as default shell for human users
for uhome in /home/*; do
    if [[ -d "$uhome" ]]; then
        username=$(basename "$uhome")
        sudo chsh -s "$ZSH_BIN" "$username" || true
    fi
done

echo ""
echo "✅ System-wide Zsh installation complete!"
echo "All human users will now start in Zsh by default."
echo "Interactive shells can now run 'p10k configure' immediately."
echo "Shell path: $ZSH_BIN"
