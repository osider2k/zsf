#!/usr/bin/env bash
set -e

# Detect package manager
if command -v apt &>/dev/null; then
    PKG_INSTALL="sudo apt update && sudo apt install -y zsh git curl fonts-powerline"
elif command -v dnf &>/dev/null; then
    PKG_INSTALL="sudo dnf install -y zsh git curl powerline-fonts"
elif command -v yum &>/dev/null; then
    PKG_INSTALL="sudo yum install -y zsh git curl powerline-fonts"
elif command -v pacman &>/dev/null; then
    PKG_INSTALL="sudo pacman -Syu --noconfirm zsh git curl powerline-fonts"
else
    echo "Unsupported Linux distro. Please install zsh, git, curl manually."
    exit 1
fi

echo "Installing dependencies..."
eval "$PKG_INSTALL"

# Download and run latest install_zsh.sh
INSTALL_URL="https://raw.githubusercontent.com/osider2k/zoxide/refs/heads/main/install_zsh.sh"
echo "Downloading the latest install script..."
curl -fsSL "$INSTALL_URL" -o /tmp/install_zsh.sh
chmod +x /tmp/install_zsh.sh
echo "Running the install script..."
/tmp/install_zsh.sh

# Install Powerlevel10k if not already
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Set Zsh theme to Powerlevel10k in .zshrc
if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc" || echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
fi

# Ask to configure Powerlevel10k
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

echo "Done! Zsh with Powerlevel10k is installed."
