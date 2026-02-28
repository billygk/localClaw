# Full openclaw/Dockerfile definition
FROM node:22-slim

# Install core system dependencies required by OpenClaw's shell tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nano \
    chromium \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Configured passwordless sudo execution specifically for the 'node' user.
# This allows the autonomous agent to run commands like 'sudo apt-get install'
# without getting blocked by an interactive password prompt it cannot fulfill.
RUN echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node

# Created a mandatory executable wrapper for Chromium.
# Docker's default security profile strips the capabilities Chromium needs to build its sandbox.
# This wrapper forcefully injects the required flags to prevent the browser from silently segfaulting.
RUN echo '#!/bin/bash\nexec /usr/bin/chromium --no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu "$@"' > /usr/local/bin/chromium-docker \
    && chmod +x /usr/local/bin/chromium-docker


# Switch to non-root user for security scoping
USER node
WORKDIR /home/node

# Configure npm prefix to allow global installs without root privileges
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin
# Injected environment variables to explicitly map the browser path.
# Node automation frameworks often attempt to download their own binaries and fail in slim containers.
# These variables force OpenClaw to use our system-installed Chromium binary.
ENV CHROME_BIN=/usr/local/bin/chromium-docker
ENV PUPPETEER_EXECUTABLE_PATH=/usr/local/bin/chromium-docker
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/bin/chromium-docker

# Install the latest OpenClaw package
RUN npm install -g openclaw@latest

# Ensure explicit directory creation for volume mapping targets
RUN mkdir -p /home/node/.openclaw /home/node/workspace

EXPOSE 18789

# Replaced the incorrect 'start' command with 'gateway run'.
# 'gateway run' correctly starts the OpenClaw gateway in the foreground,
# bypassing the need for systemd while keeping the Docker container alive.
CMD npx openclaw gateway run