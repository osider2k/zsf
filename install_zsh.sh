#!/usr/bin/env bash
set -euo pipefail
# clean-zsh-p10k.sh
# Clean install of zsh + Oh My Zsh + Powerlevel10k (official method)

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

# 3) Remove old zsh package and clean old dependencies
apt remove -y zsh || true
apt purge -y zsh || true
apt autoremove -y

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

# 7) Install Powerlevel10k theme using official ZSH_CUSTOM method
su - "$TARGET_USER" -c 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"'

# 8) Update .zshrc to activate Powerlevel10k theme safely
ZSHRC="$TARGET_HOME/.zshrc"

# Comment out any existing ZSH_THEME lines
if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
    sed -i 's/^ZSH_THEME=/#&/' "$ZSHRC"
fi

# Add the new Powerlevel10k theme line if it doesn’t already exist
if ! grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC" 2>/dev/null; then
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

# 9) Ask if user wants to run p10k configure
read -rp "Do you want to run Powerlevel10k configuration now? (y/n): " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    su - "$TARGET_USER" -c 'p10k configure'
fi

# 10) Prompt to start using zsh immediately
read -rp "Do you want to start a new zsh session now? (y/n): " use_zsh
if [[ "$use_zsh" =~ ^[Yy]$ ]]; then
    echo "Starting zsh..."
    exec "$ZSH_BIN"
else
    echo "You can start zsh later by running: zsh"
fi

echo "Clean zsh + Oh My Zsh + Powerlevel10k installation complete!"
echo "Log out and log back in (or start a new session) to use zsh."
