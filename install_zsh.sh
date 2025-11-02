#!/usr/bin/env bash
set -euo pipefail
# clean-zsh-p10k.sh
# Clean install of zsh + Oh My Zsh + Powerlevel10k (official method)
# Shows a progress bar for cleaning old configs/packages

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"

echo "Running clean install for user: $TARGET_USER (home: $TARGET_HOME)"

# 1) Switch to bash for safety
export SHELL="/bin/bash"
echo "Switched to bash for script session"

# ------------------------------
# 2) Cleaning old zsh and configs (with progress bar)
# ------------------------------
echo "Cleaning old zsh and configs..."
CLEAN_STEPS=5

for i in $(seq 1 $CLEAN_STEPS); do
    case $i in
        1) rm -rf "$TARGET_HOME/.oh-my-zsh" ;;
        2) rm -f "$TARGET_HOME/.zshrc" ;;
        3) rm -f "$TARGET_HOME/.p10k.zsh" ;;
        4) apt remove -y zsh >/dev/null 2>&1 || true ;;
        5) apt purge -y zsh >/dev/null 2>&1 || true
           apt autoremove -y >/dev/null 2>&1 ;;
    esac

    # Print progress bar
    PERCENT=$(( i * 20 ))
    BAR="["
    FILLED=$(( PERCENT / 2 ))  # 50 chars max
    for j in $(seq 1 $FILLED); do BAR+="="; done
    for j in $(seq $((FILLED+1)) 50); do BAR+=" "; done
    BAR+="]"
    echo -ne " $BAR $PERCENT%\r"
    sleep 0.2
done
echo -e "\nCleaning complete!"

# 3) Update & install fresh zsh + tools
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --no-install-recommends zsh git curl ca-certificates

ZSH_BIN="$(command -v zsh)"
[[ -z "$ZSH_BIN" ]] && { echo "zsh not found after install — aborting."; exit 1; }

# 4) Install Oh My Zsh fresh (non-interactive)
su - "$TARGET_USER" -c 'export RUNZSH=no CHSH=no; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# 5) Set default shell
CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7 || true)"
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    chsh -s "$ZSH_BIN" "$TARGET_USER" || echo "chsh failed — run manually: sudo chsh -s $ZSH_BIN $TARGET_USER"
fi

# 6) Install Powerlevel10k theme using official ZSH_CUSTOM method
su - "$TARGET_USER" -c 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"'

# 7) Update .zshrc to activate Powerlevel10k theme safely
ZSHRC="$TARGET_HOME/.zshrc"

# Comment out any existing ZSH_THEME lines
if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
    sed -i 's/^ZSH_THEME=/#&/' "$ZSHRC"
fi

# Add the new Powerlevel10k theme line if it doesn’t already exist
if ! grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC" 2>/dev/null; then
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

# 8) Final message and prompt to exit session
echo
echo "============================================================"
echo "Installation complete!"
echo "To activate zsh and launch Powerlevel10k configuration:"
echo "  1) Close this terminal or exit the current session"
echo "  2) Start a new terminal session or SSH login"
echo "============================================================"
read -rp "Press Enter to exit this session..."
exit
