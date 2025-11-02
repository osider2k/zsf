#!/bin/bash

# --- 0. Configuration & Initialization ---

# Extend sudo privileges for script duration
sudo -v
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
PLUGINS_LIST="(git zsh-autosuggestions zsh-syntax-highlighting)"
CURRENT_USER=$(whoami)
CURRENT_USER_HOME=$(eval echo "~$CURRENT_USER")

# --- Function Definitions ---

# Runs commands with retained sudo permission
run_as_root() {
    # Ensure commands run in a Bash shell environment when elevated
    sudo /bin/bash -c "$1"
}

# Runs commands as the original user (not root)
run_as_user() {
    sudo -u "$CURRENT_USER" /bin/bash -c "$1"
}

# Checks if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Force clean removal of a directory
clean_up_previous_installs() {
    local DIR="$1"
    local NAME="$2"
    if [ -d "$DIR" ]; then
        echo "💣 Removing existing $NAME directory: $DIR"
        run_as_root "rm -rf \"$DIR\""
    fi
}

# Force a fresh clone (clean install guarantee)
force_git_clone() {
    local DIR="$1"
    local REPO="$2"
    local NAME="$3"

    clean_up_previous_installs "$DIR" "$NAME"

    echo "✨ Installing $NAME (Cloning fresh repository)..."
    if run_as_root "git clone --depth=1 \"$REPO\" \"$DIR\""; then
        echo "✅ $NAME installed successfully."
    else
        echo "❌ Error: Failed to clone $NAME from $REPO. Exiting."
        exit 1
    fi
}

# --- 1. System Package Installation ---

echo "--- 1. Checking/Installing Zsh and Git Packages ---"

# Determine package manager and install dependencies
declare PKG_INSTALL
if command_exists apt; then
  PKG_INSTALL="apt update && apt install -y"
elif command_exists dnf; then
  PKG_INSTALL="dnf install -y"
elif command_exists pacman; then
  PKG_INSTALL="pacman -S --noconfirm"
else
  echo "❌ Error: Cannot find a supported package manager (apt, dnf, pacman). Exiting."
  exit 1
fi

ZSH_BIN=$(command -v zsh)

if [ -z "$ZSH_BIN" ]; then
    echo "Zsh package missing. Installing packages..."
    run_as_root "$PKG_INSTALL zsh git curl wget"
    ZSH_BIN=$(command -v zsh)
    if [ -z "$ZSH_BIN" ]; then
        echo "❌ Fatal Error: Zsh installation failed. Exiting."
        exit 1
    fi
else
    echo "Zsh package is already installed."
fi

# --- 2. Configure System Defaults ---

echo "--- 2. Setting Zsh as the default shell for NEW users ---"
if [ -f /etc/adduser.conf ]; then
    run_as_root "sed -i 's/^DSHELL=.*$/DSHELL=\/bin\/zsh/' /etc/adduser.conf"
fi
if [ -f /etc/default/useradd ]; then
    run_as_root "sed -i 's/^SHELL=.*$/SHELL=\/bin\/zsh/' /etc/default/useradd"
fi
echo "New user defaults updated."

# --- 3. Clean Install Components (Shared) ---

echo "--- 3. Clean Install Zsh Components (Shared) ---"

# Oh My Zsh Framework
force_git_clone "${OMZ_SHARED_DIR}" "https://github.com/ohmyzsh/ohmyzsh.git" "Oh My Zsh Framework"
run_as_root "mkdir -p ${OMZ_CUSTOM_SHARED_DIR}/themes ${OMZ_CUSTOM_SHARED_DIR}/plugins"

# Powerlevel10k Theme
force_git_clone "${THEMES_DIR}/powerlevel10k" "$P10K_REPO" "Powerlevel10k Theme"

# Plugins
force_git_clone "${PLUGINS_DIR}/zsh-autosuggestions" "$AUTO_SUGGESTIONS_REPO" "zsh-autosuggestions Plugin"
force_git_clone "${PLUGINS_DIR}/zsh-syntax-highlighting" "$SYNTAX_HIGHLIGHTING_REPO" "zsh-syntax-highlighting Plugin"

# --- 4. Configure /etc/skel for All New Users ---

echo "--- 4. Configuring /etc/skel for ALL new users ---"

# Create/overwrite the default .zshrc template
run_as_root "cp -f ${OMZ_SHARED_DIR}/templates/zshrc.zsh-template ${SKEL_ZSHRC}"
run_as_root "chmod 644 $SKEL_ZSHRC"

# Apply settings to the template
echo "Applying Zsh configuration settings to $SKEL_ZSHRC..."
run_as_root "sed -i 's|^export ZSH=.*$|export ZSH=\"${OMZ_SHARED_DIR}\"|' ${SKEL_ZSHRC}"
run_as_root "sed -i 's|^ZSH_THEME=.*$|ZSH_THEME=\"powerlevel10k\/powerlevel10k\"|' ${SKEL_ZSHRC}"
run_as_root "sed -i 's|^plugins=.*$|plugins=${PLUGINS_LIST}|' ${SKEL_ZSHRC}"

# Create p10k config file placeholder
run_as_root "echo '# P10k configuration (wizard will run on first launch)' > /etc/skel/.p10k.zsh"
run_as_root "chmod 644 /etc/skel/.p10k.zsh"

# --- 5. Configure Current User ---

echo "--- 5. Configuring Current User ($CURRENT_USER) ---"

# Set Zsh as the default shell for the current user
if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$ZSH_BIN" ]; then
    if command_exists chsh; then
        echo "Setting Zsh as permanent default shell via chsh. **Your user password may be required.**"
        chsh -s "$ZSH_BIN" "$CURRENT_USER"
    fi
fi

# Overwrite current user's config files to ensure a clean start and P10k launch
echo "Overwriting current user's config files (~/.zshrc and ~/.p10k.zsh)..."
run_as_user "cp -f $SKEL_ZSHRC $CURRENT_USER_HOME/.zshrc"
run_as_user "cp -f /etc/skel/.p10k.zsh $CURRENT_USER_HOME/.p10k.zsh"
run_as_user "chmod 644 $CURRENT_USER_HOME/.zshrc $CURRENT_USER_HOME/.p10k.zsh"

# --- 6. User Prompt and Execution ---

echo ""
echo "======================================================================"
echo "Installation and configuration are complete."
echo ""
echo "🔥 **IMPORTANT:**"
echo "* You must **manually install a Nerd Font** on your system (e.g., MesloLGS NF) for P10k to display correctly."
echo "* You must **log out and log back in** for Zsh to be your permanent default shell."
echo "======================================================================"

# Ask the user if they want to run the interactive setup
read -r -p "Do you want to start Zsh now to run the Powerlevel10k configuration wizard? (Y/n): " response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Starting Zsh for interactive setup..."
    echo "======================================================================"
    # Execute Zsh, which will start the p10k configure wizard
    exec "$ZSH_BIN"
else
    echo "Installation completed. The P10k configuration wizard will run the next time you start Zsh."
    echo "Run 'zsh' or log out/in to begin using your new shell."
fi
