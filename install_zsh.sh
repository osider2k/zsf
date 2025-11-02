#!/usr/bin/env bash
set -euo pipefail
# Minimal system-wide zsh + Oh My Zsh + Powerlevel10k installer

echo "Running system-wide zsh + Oh My Zsh + Powerlevel10k installer..."

# ------------------------------
# 1) Install zsh system-wide
# ------------------------------
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="/usr/bin/zsh"
[[ ! -x "$ZSH_BIN" ]] && { echo "zsh not found at $ZSH_BIN — aborting."; exit 1; }

# ------------------------------
# 2) Install Oh My Zsh system-wide
# ------------------------------
OHMYZSH_DIR="/usr/share/oh-my-zsh"
if [[ ! -d "$OHMYZSH_DIR" ]]; then
    echo "Installing Oh My Zsh to $OHMYZSH_DIR..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_DIR"
fi

# ------------------------------
# 3) Install Powerlevel10k system-wide
# ------------------------------
THEME_DIR="$OHMYZSH_DIR/custom/themes/powerlevel10k"
if [[ ! -d "$THEME_DIR" ]]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
fi

# ------------------------------
# 4) Setup global .zshrc for new users
# ------------------------------
ZSHRC_SKEL="/etc/skel/.zshrc"
if [[ ! -f "$ZSHRC_SKEL" ]]; then
    cp "$OHMYZSH_DIR/templates/zshrc.zsh-template" "$ZSHRC_SKEL"
fi

# Comment out existing ZSH_THEME lines and add Powerlevel10k
sed -i 's/^ZSH_THEME=/#&/' "$ZSHRC_SKEL"
if ! grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC_SKEL"; then
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC_SKEL"
fi

# ------------------------------
# 5) Change current user's shell
# ------------------------------
chsh -s "$ZSH_BIN"

# ------------------------------
# 6) Set default shell for new users
# ------------------------------
if grep -q '^SHELL=' /etc/default/useradd; then
    sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
else
    echo "SHELL=/usr/bin/zsh" >> /etc/default/useradd
fi

# ------------------------------
# 7) Done message
# ------------------------------
echo
echo "============================================================"
echo "System-wide zsh + Oh My Zsh + Powerlevel10k installation complete!"
echo "Current user shell changed to zsh."
echo "New users will automatically get zsh + Powerlevel10k."
echo "To start using zsh, log out and log back in, or open a new terminal."
echo "Powerlevel10k configuration wizard will run on first zsh launch."
echo "============================================================"
