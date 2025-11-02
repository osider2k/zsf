#!/bin/bash
set -euo pipefail

# --- 0. Configuration & Initialization ---

# Keep sudo alive for the script duration
sudo -v
( while true; do sudo -v; sleep 60; done ) &  # Refresh sudo timestamp in background
SUDO_REFRESH_PID=$!
trap 'kill $SUDO_REFRESH_PID 2>/dev/null' EXIT

echo "Sudo permissions granted for the script duration."

# Shared directories
OMZ_SHARED_DIR="/usr/share/oh-my-zsh"
OMZ_CUSTOM_SHARED_DIR="${OMZ_SHARED_DIR}/custom"

# Component repositories and paths
PLUGINS_DIR="${OMZ_CUSTOM_SHARED_DIR}/plugins"
THEMES_DIR="${OMZ_CUSTOM_SHARED_DIR}/themes"

P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
AUTO_SUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Configuration settings
SKEL_ZSHRC="/etc/skel/.zshrc"
PLUGINS_LIST='(git zsh-autosuggestions zsh-syntax-highlighting)'
CURRENT_USER=$(logname 2>/dev/null || echo "$USER")
CURRENT_USER_HOME=$(eval echo "~$CURRENT_USER")

# --- Function Definitions ---

run_as_root() {
    sudo bash -c "$1"
}

run_as_user() {
    sudo -u "$CURRENT_USER" bash -c "$1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

clean_up_previous_installs() {
    local DIR="$1"
    local NAME="$2"
    if [ -d "$DIR" ]; then
        echo "💣 Removing existing $NAME directory: $DIR"
        run_as_root "rm -rf '$DIR'"
    fi
}

force_git_clone() {
    local DIR="$1"
    local REPO="$2"
    local NAME="$3"

    clean_up_previous_installs "$DIR" "$NAME"
    echo "✨ Installing $NAME..."
    if run_as_root "git clone --depth=1 '$REPO' '$DIR'"; then
        echo "✅ $NAME installed successfully."
    else
        echo "❌ Error: Failed to clone $NAME from $REPO. Exiting."
        exit 1
    fi
}

# --- 1. System Package Installation ---

echo "--- 1. Checking/Installing Zsh and Git Packages ---"

if command_exists apt; then
  PKG_INSTALL="apt update -y && apt install -y"
elif command_exists dnf; then
  PKG_INSTALL="dnf install -y"
elif command_exists pacman; then
  PKG_INSTALL="pacman -Sy --noconfirm"
else
  echo "❌ Error: No supported package manager found."
  exit 1
fi

ZSH_BIN=$(command -v zsh || true)

if [ -z "$ZSH_BIN" ]; then
    echo "Installing zsh, git, curl, and wget..."
    run_as_root "$PKG_INSTALL zsh git curl wget"
    ZSH_BIN=$(command -v zsh || true)
    if [ -z "$ZSH_BIN" ]; then
        echo "❌ Fatal Error: Zsh installation failed. Exiting."
        exit 1
    fi
else
    echo "Zsh package already installed."
fi

# --- 2. Configure System Defaults ---

echo "--- 2. Setting Zsh as the default shell for NEW users ---"
if [ -f /etc/adduser.conf ]; then
    run_as_root "sed -i 's|^DSHELL=.*$|DSHELL=/bin/zsh|' /etc/adduser.conf"
fi
if [ -f /etc/default/useradd ]; then
    run_as_root "sed -i 's|^SHELL=.*$|SHELL=/bin/zsh|' /etc/default/useradd"
fi
echo "Default shell updated."

# --- 3. Clean Install Components (Shared) ---

echo "--- 3. Installing Oh My Zsh + plugins/themes ---"

force_git_clone "$OMZ_SHARED_DIR" "https://github.com/ohmyzsh/ohmyzsh.git" "Oh My Zsh"
run_as_root "mkdir -p '$OMZ_CUSTOM_SHARED_DIR/themes' '$OMZ_CUSTOM_SHARED_DIR/plugins'"

force_git_clone "$THEMES_DIR/powerlevel10k" "$P10K_REPO" "Powerlevel10k Theme"
force_git_clone "$PLUGINS_DIR/zsh-autosuggestions" "$AUTO_SUGGESTIONS_REPO" "zsh-autosuggestions Plugin"
force_git_clone "$PLUGINS_DIR/zsh-syntax-highlighting" "$SYNTAX_HIGHLIGHTING_REPO" "zsh-syntax-highlighting Plugin"

# --- 4. Configure /etc/skel for All New Users ---

echo "--- 4. Configuring /etc/skel for new users ---"

run_as_root "cp -f '$OMZ_SHARED_DIR/templates/zshrc.zsh-template' '$SKEL_ZSHRC'"
run_as_root "chmod 644 '$SKEL_ZSHRC'"

run_as_root "sed -i 's|^export ZSH=.*$|export ZSH=\"${OMZ_SHARED_DIR}\"|' '$SKEL_ZSHRC'"
run_as_root "sed -i 's|^ZSH_THEME=.*$|ZSH_THEME=\"powerlevel10k/powerlevel10k\"|' '$SKEL_ZSHRC'"
run_as_root "sed -i 's|^plugins=.*$|plugins=${PLUGINS_LIST}|' '$SKEL_ZSHRC'"

run_as_root "echo '# P10k configuration placeholder' > /etc/skel/.p10k.zsh"
run_as_root "chmod 644 /etc/skel/.p10k.zsh"

# --- 5. Configure Current User ---

echo "--- 5. Configuring current user: $CURRENT_USER ---"

if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$ZSH_BIN" ]; then
    if command_exists chsh; then
        echo "Setting Zsh as default shell for $CURRENT_USER..."
        run_as_root "chsh -s '$ZSH_BIN' '$CURRENT_USER'"
    fi
fi

echo "Copying configuration files to $CURRENT_USER_HOME ..."
run_as_user "cp -f '$SKEL_ZSHRC' '$CURRENT_USER_HOME/.zshrc'"
run_as_user "cp -f /etc/skel/.p10k.zsh '$CURRENT_USER_HOME/.p10k.zsh'"
run_as_user "chmod 644 '$CURRENT_USER_HOME/.zshrc' '$CURRENT_USER_HOME/.p10k.zsh'"

# --- 6. Final Notes ---

echo ""
echo "======================================================================"
echo "✅ Installation and configuration complete."
echo ""
echo "🔥 IMPORTANT:"
echo "* Install a Nerd Font (e.g., MesloLGS NF) for Powerlevel10k to render properly."
echo "* Log out and log back in to start using Zsh by default."
echo "======================================================================"

read -rp "Start Zsh now to run Powerlevel10k configuration? (Y/n): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    exec "$ZSH_BIN"
else
    echo "Run 'zsh' manually when ready."
fi
