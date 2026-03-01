#!/usr/bin/env bash
set -e

# Configuration variables
APP_USER="openclaw"
NODE_VERSION="22"

echo "Updating system packages..."
apt-get update && apt-get upgrade -y

echo "Installing base dependencies..."
# CHANGE: Added build-essential to the requested list, as it is frequently required for compiling native bindings in npm packages.
apt-get install -y curl git python3 build-essential

echo "Provisioning Node.js ${NODE_VERSION}..."
# CHANGE: Ubuntu 24.04 default repos lack Node 22+. Switched to the NodeSource repository.
# Note: The NodeSource nodejs package bundles npm, so a separate 'apt-get install npm' is omitted to prevent package conflicts.
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs

echo "Creating user: ${APP_USER}..."
if id "$APP_USER" &>/dev/null; then
    echo "User ${APP_USER} already exists."
else
    useradd -m -s /bin/bash "$APP_USER"
fi

# ADDITION: Add to sudo group
# usermod -aG sudo "$APP_USER"

# CHANGE: Enabled systemd linger for the user. This is a strict requirement for a non-root user to run persistent background daemons.
loginctl enable-linger "$APP_USER"

echo "Installing OpenClaw as ${APP_USER}..."
# CHANGE: Using sudo to drop privileges and execute the remainder of the installation strictly within the new user's context.
sudo -u "$APP_USER" bash << 'EOF'

# CHANGE: Configured a local npm prefix. Without this, 'npm install -g' attempts to write to /usr/lib and will fail for a non-root user.
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Ensure the local npm binary directory is in the PATH for this session and future interactive sessions.
if ! grep -q ".npm-global/bin" ~/.bashrc; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
fi
export PATH=~/.npm-global/bin:$PATH

echo "Running npm install for OpenClaw..."
npm install -g openclaw@latest

echo "Starting OpenClaw onboard wizard..."
# NOTE: If this binary strictly demands system-level systemd access (/etc/systemd/system), it will fail here due to lack of sudo.
openclaw onboard --install-daemon

EOF

echo "Installation sequence finished."
echo "To access the Web UI securely, establish an SSH tunnel from your local machine:"
echo "ssh -L 18789:localhost:18789 root@<your_vm_ip>"


