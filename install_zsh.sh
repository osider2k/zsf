#!/usr/bin/env bash
set -euo pipefail
# clean-install-zsh.sh
# Clean old zsh + oh-my-zsh, then fresh install

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"

echo "Cleaning old zsh and oh-my-zsh for user: $TARGET_USER"

# 1) Switch to bash for safety (only for current session)
export SHELL="/bin/bash"
echo "Switched to bash for script session"

# 2) Remove old zsh configs and Oh My Zsh
if [[ -d "$TARGET_HOME/.oh-my-zsh" ]]; then
    echo "Removing $TARGET_HOME/.oh-my-zsh"
    rm -rf "$TARGET_HOME/.oh-my-zsh"
fi

if [[ -f "$TARGET_HOME/.zshrc" ]]; then
    echo "Removing $TARGET_HOME/.zshrc"
    rm -f "$TARGET_HOME/.zshrc"
fi

# Optional: remove old zsh package and reinstall
apt remove -y zsh || true
apt purge -y zsh || true

# Optional: clean old repos if you know them
# Example: rm -rf ~/old-zsh-repo
# Add your repo paths here if needed

# 3) Update & install fresh zsh
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --no-install-recommends zsh git curl ca-certificates

# 4) Install Oh My Zsh fresh
su - "$TARGET_USER" -c 'export RUNZSH=no CHSH=no; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# 5) Set default shell to new zsh
ZSH_BIN="$(command -v zsh)"
chsh -s "$ZSH_BIN" "$TARGET_USER" || echo "chsh failed — run manually: sudo chsh -s $ZSH_BIN $TARGET_USER"

echo "Clean zsh installation complete. Log out and log back in to start using zsh."
