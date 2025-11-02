#!/usr/bin/env bash
set -euo pipefail
# clean-zsh-p10k.sh
# Clean install of zsh + Oh My Zsh + optional Powerlevel10k
# Usage: curl -fsSL <RAW_URL> | sudo bash

# Setup sudo until script finish
sudo -v


TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"

echo "Running clean install for user: $TARGET_USER (home: $TARGET_HOME)"

# 1) Switch to bash for safety
export SHELL="/bin/bash"
echo "Switched to bash for script session"

# 2) Remove old zsh configs & Oh My Zsh
[[ -d "$TARGET_HOME/.oh-my-zsh" ]] && rm -rf "$TARGET_HOME/.oh-my-zsh"
[[ -f "$TARGET_HOME/.zshrc" ]] && rm -f "$TARGET_HOME/.zshrc"
[[ -f "$TARGET_HOME/.p10k.zsh" ]] && rm -f "$TARGET_HOME/.p10k.zsh"

# 3) Remove old zsh package
apt remove -y zsh || true
apt purge -y zsh || true

# 4) Update & install fresh zsh + tools
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "zsh not found after install — aborting."; exit 1; }

# 5) Install Oh My Zsh fresh (non-interactive)
su - "$TARGET_USER" -c 'export RUNZSH=no CHSH=no; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# 6) Set default shell
CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7 || true)"
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    chsh -s "$ZSH_BIN" "$TARGET_USER" || echo "chsh failed — run manually: sudo chsh -s $ZSH_BIN $TARGET_USER"
fi

# 7) Optional: Install Powerlevel10k theme
P10K_DIR="$TARGET_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing Powerlevel10k theme..."
    su - "$TARGET_USER" -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$P10K_DIR\""
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$TARGET_HOME/.zshrc"
fi

chsh -s /usr/bin/zsh

echo "Clean zsh + Oh My Zsh installation complete!"
echo "Log out and log back in (or start a new session) to use zsh."
