#!/usr/bin/env bash
set -e

# Prevent multiple executions
[[ -n "$INSTALL_ZSH_P10K_DONE" ]] && exit 0
export INSTALL_ZSH_P10K_DONE=1

echo "=== Zsh + Powerlevel10k Setup ==="

# Install dependencies
if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh git curl fonts-powerline
elif command -v dnf &>/dev/null; then
    sudo dnf install -y zsh git curl powerline-fonts
elif command -v yum &>/dev/null; then
    sudo yum install -y zsh git curl powerline-fonts
elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm zsh git curl powerline-fonts
fi

# Download install_zsh.sh once
INSTALL_URL="https://raw.githubusercontent.com/osider2k/zsf/refs/heads/main/install_zsh.sh"
TMP_INSTALL="/tmp/install_zsh.sh"
curl -fsSL "$INSTALL_URL" -o "$TMP_INSTALL"
chmod +x "$TMP_INSTALL"

# Run install_zsh.sh in a subshell to prevent looping
echo "Running install_zsh.sh..."
bash "$TMP_INSTALL"

# Install Powerlevel10k if missing
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
[[ ! -d "$P10K_DIR" ]] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"

# Set Zsh theme to Powerlevel10k
if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc" || \
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
fi

# Prompt to configure Powerlevel10k
read -rp "Do you want to configure Powerlevel10k now? (y/n): " ans
[[ $ans =~ [Yy] ]] && zsh -c 'p10k configure'

echo "✅ Zsh + Powerlevel10k installation finished!"
