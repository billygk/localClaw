#!/usr/bin/env bash
# install_user_homebrew.sh
set -e

APP_USER="openclaw"

echo "Verifying execution context..."
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root to install OS prerequisites."
    exit 1
fi

echo "Creating user: ${APP_USER}..."
if id "$APP_USER" &>/dev/null; then
    echo "User ${APP_USER} already exists."
else
    useradd -m -s /bin/bash "$APP_USER"
fi

echo "Installing OS-level compilers required by Homebrew..."
# Homebrew requires these base tools to compile its own dependency tree on Linux
apt-get update
apt-get install -y build-essential procps curl file git gcc

echo "Executing non-interactive Homebrew installation for ${APP_USER}..."
# We use sudo to switch to the openclaw user.
# NONINTERACTIVE=1 forces the installer to bypass the "Press ENTER" prompt.
# Because the user lacks sudo privileges, Homebrew will cleanly fall back 
# and install itself into /home/openclaw/.linuxbrew
sudo -u "$APP_USER" bash << 'EOF'
    # Force non-interactive mode
    export NONINTERACTIVE=1
    
    # Run the official Homebrew install script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo "Wiring Homebrew into the user's bash profile..."
    BREW_ENV_CMD='eval "$(/home/openclaw/.linuxbrew/bin/brew shellenv)"'
    
    # Append to .bashrc if it's not already there
    if ! grep -q ".linuxbrew/bin/brew" ~/.bashrc; then
        echo "$BREW_ENV_CMD" >> ~/.bashrc
    fi
    
    # Evaluate it for the current temporary shell session to verify
    eval "$(/home/openclaw/.linuxbrew/bin/brew shellenv)"
    
    echo "Verifying Homebrew installation..."
    brew --version
EOF

echo "================================================================"
echo "Homebrew successfully installed in /home/${APP_USER}/.linuxbrew"
echo "To use it, switch to the user:"
echo "  su - ${APP_USER}"
echo "  brew doctor"
echo "================================================================"
