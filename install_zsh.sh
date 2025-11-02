#!/usr/bin/env bash
set -e

echo "=== Zsh + Powerlevel10k Setup ==="

# Detect package manager and install dependencies
echo "Installing dependencies..."
if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh git curl fonts-powerline
elif command -v dnf &>/dev/null; then
    sudo dnf install -y zsh git curl powerline-fonts
elif command -v yum &>/dev/null; then
    sudo yum install -y zsh git curl powerline-fonts
elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm zsh git curl powerline-fonts
else
    echo "Unsupported Linux distro. Please install zsh, git, curl manually."
    exit 1
fi

# Download install_zsh.sh once and execute
INSTALL_URL="https://raw.githubusercontent.com/osider2k/zsf/refs/heads/main/install_zsh.sh"
TMP_INSTALL="/tmp/install_zsh.sh"
echo "Downloading latest install_zsh.sh..."
curl -fsSL "$INSTALL_URL" -o "$TMP_INSTALL"
chmod +x "$TMP_INSTALL"
echo "Running install_zsh.sh..."
"$TMP_INSTALL"

# Install Powerlevel10k if missing
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Set Zsh theme to Powerlevel10k
if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc" || \
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
fi

# Prompt to configure Powerlevel10k
echo ""
read -rp "Do you want to configure Powerlevel10k now? (y/n): " answer
case "$answer" in
    [Yy]* )
        echo "Starting Powerlevel10k configuration..."
        exec zsh -c 'p10k configure'
        ;;
    * )
        echo "You can configure Powerlevel10k later by running: p10k configure"
        ;;
esac

echo "✅ Zsh + Powerlevel10k installation finished!"
