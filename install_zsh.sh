#!/usr/bin/env bash
set -euo pipefail
# install_zsh_systemwide.sh
# System-wide Zsh + Oh My Zsh + Powerlevel10k + plugins
# Usage: curl -fsSL <RAW_URL> | sudo bash

echo "=== System-wide Zsh + Oh My Zsh + Powerlevel10k + Plugins Installation ==="

sudo -v

# -----------------------------------------------------
# 1) Remove any old system installations
# -----------------------------------------------------
sudo rm -rf /usr/share/oh-my-zsh || true
sudo rm -f /etc/skel/.zshrc /etc/skel/.p10k.zsh || true

# -----------------------------------------------------
# 2) Install required packages
# -----------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "❌ zsh not found after install"; exit 1; }

# -----------------------------------------------------
# 3) Install Oh My Zsh system-wide
# -----------------------------------------------------
echo "Installing Oh My Zsh..."
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

# -----------------------------------------------------
# 4) Install Powerlevel10k theme
# -----------------------------------------------------
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# -----------------------------------------------------
# 5) Install system-wide Zsh plugins
# -----------------------------------------------------
PLUGINS_DIR="/usr/share/zsh-plugins"
sudo mkdir -p "$PLUGINS_DIR"

# zsh-autosuggestions
if [[ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]]; then
    echo "Installing zsh-autosuggestions..."
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGINS_DIR/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [[ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
    echo "Installing zsh-syntax-highlighting..."
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
fi

# -----------------------------------------------------
# 6) Configure default .zshrc for new users
# -----------------------------------------------------
sudo cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
sudo sed -i 's|ZSH=.*|ZSH=/usr/share/oh-my-zsh|' /etc/skel/.zshrc
sudo sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /etc/skel/.zshrc

# Append system-wide plugins
sudo tee -a /etc/skel/.zshrc >/dev/null <<'EOF'

# === System-wide Zsh plugins ===
source /usr/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF

# -----------------------------------------------------
# 7) Copy .zshrc to new users (without overwriting existing)
# -----------------------------------------------------
for uhome in /home/*; do
    if [[ -d "$uhome" && ! -f "$uhome/.zshrc" ]]; then
        sudo cp /etc/skel/.zshrc "$uhome/.zshrc"
        sudo chown "$(basename "$uhome")":"$(basename "$uhome")" "$uhome/.zshrc"
    fi
done

# -----------------------------------------------------
# 8) Append plugins to existing users' .zshrc safely
# -----------------------------------------------------
for uhome in /home/*; do
    [ -d "$uhome" ] || continue
    user=$(basename "$uhome")
    zshrc="$uhome/.zshrc"

    [ -f "$zshrc" ] || continue

    if ! grep -q "zsh-autosuggestions" "$zshrc"; then
        echo "" | sudo tee -a "$zshrc" >/dev/null
        echo "# === System-wide Zsh plugins ===" | sudo tee -a "$zshrc" >/dev/null
        echo "source /usr/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" | sudo tee -a "$zshrc" >/dev/null
    fi

    if ! grep -q "zsh-syntax-highlighting" "$zshrc"; then
        echo "source /usr/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" | sudo tee -a "$zshrc" >/dev/null
    fi

    sudo chown "$user:$user" "$zshrc"
done

# -----------------------------------------------------
# 9) Set Zsh as default shell globally
# -----------------------------------------------------
echo "Setting Zsh as default shell for all users..."
if ! grep -q "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi
sudo sed -i "s|/bin/bash|$ZSH_BIN|g" /etc/passwd

# -----------------------------------------------------
echo ""
echo "✅ System-wide Zsh installation complete!"
echo "All users will now start in Zsh by default."
echo "Type 'p10k configure' to run the Powerlevel10k setup."
echo "Shell path: $ZSH_BIN"

# -----------------------------------------------------
# 10) Source .zshrc for current and existing users
# -----------------------------------------------------
echo "Sourcing .zshrc for current user..."
if [[ -f ~/.zshrc ]]; then
    source ~/.zshrc
fi

echo "Sourcing .zshrc for existing users..."
for uhome in /home/*; do
    [ -d "$uhome" ] || continue
    user=$(basename "$uhome")
    zshrc="$uhome/.zshrc"

    [ -f "$zshrc" ] || continue

    # Use sudo -u to run source in a subshell as that user
    sudo -u "$user" zsh -c "source $zshrc"
done

echo "✅ All users' Zsh environments have been updated."

