#!/usr/bin/env bash
# configure_global_openclaw_service.sh
set -e

APP_USER="openclaw"

echo "Verifying execution context..."
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root to manage /etc/systemd/system/."
    exit 1
fi

# CHANGE: Proactively removing the previous user-level systemd unit to prevent duplicate processes or conflicts.
echo "Cleaning up previous user-level systemd configurations..."
if [ -f "/home/$APP_USER/.config/systemd/user/openclaw.service" ]; then
    sudo -u "$APP_USER" XDG_RUNTIME_DIR="/run/user/$(id -u $APP_USER)" systemctl --user stop openclaw.service || true
    sudo -u "$APP_USER" XDG_RUNTIME_DIR="/run/user/$(id -u $APP_USER)" systemctl --user disable openclaw.service || true
    rm -f "/home/$APP_USER/.config/systemd/user/openclaw.service"
fi

echo "Constructing system-wide unit file dropping privileges to ${APP_USER}..."

# CHANGE: Writing directly to the global systemd directory instead of the user's home directory.
# ADDITION: Added User= and Group= directives. This is the critical mechanism that allows root to control the service,.
# while the operating system ensures the process itself runs without root permissions.
cat << UNIT_FILE > /etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw AI Gateway
After=network.target

[Service]
Type=simple
# CHANGE: Explicit privilege drop to the dedicated application user.
User=${APP_USER}
Group=${APP_USER}

# CHANGE: Hardcoded absolute paths to the user's home directory since %h behavior changes in global units.
Environment="PATH=/home/${APP_USER}/.npm-global/bin:/usr/bin:/bin"
Environment="NODE_ENV=production"

# CHANGE: ExecStart uses the absolute path to the locally installed npm binary.
ExecStart=/home/${APP_USER}/.npm-global/bin/openclaw gateway --port 18789

Restart=always
RestartSec=3
SyslogIdentifier=openclaw-gateway

[Install]
WantedBy=multi-user.target
UNIT_FILE

echo "Applying global systemd configuration..."

# CHANGE: Reloading the root PID 1 daemon, not the user daemon.
systemctl daemon-reload

echo "Enabling and starting OpenClaw global service..."
# CHANGE: Standard systemctl commands can now be used natively from the root shell.
systemctl enable --now openclaw.service

echo "Verifying final service state..."
systemctl status openclaw.service --no-pager

echo "================================================================"
echo "Architecture Pivot Complete."
echo "You can now manage the service directly as root using standard commands:"
echo "  systemctl restart openclaw"
echo "  systemctl status openclaw"
echo "  journalctl -u openclaw -f"
echo "================================================================"



