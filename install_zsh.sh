#!/usr/bin/env bash
set -e

# URL to the latest install script
INSTALL_URL="https://raw.githubusercontent.com/osider2k/zoxide/refs/heads/main/install_zsh.sh"

echo "Downloading the latest install script..."
curl -fsSL "$INSTALL_URL" -o /tmp/install_zsh.sh
chmod +x /tmp/install_zsh.sh

echo "Running the install script..."
/tmp/install_zsh.sh

# Check if p10k is installed
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
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
else
    echo "Powerlevel10k theme not found. Installation might have failed."
fi
