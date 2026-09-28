#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# ASUSCTL setup for UBUNTU-based systems
# ============================================================

# -----------------------------
# Configuration
# -----------------------------

BATTERY_LIMIT=80

# -----------------------------
# Helpers
# -----------------------------

log() {
    printf '\n\033[1;32m==> %s\033[0m\n' "$1"
}

warn() {
    printf '\n\033[1;33mWARNING: %s\033[0m\n' "$1"
}

die() {
    printf '\n\033[1;31mERROR: %s\033[0m\n' "$1" >&2
    exit 1
}

# -----------------------------
# Preconditions
# -----------------------------

if [[ $EUID -eq 0 ]]; then
    die "Do not run this script as root. Run it as your normal user."
fi

if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required."
fi

sudo -v

# Keep sudo credentials alive while the script runs.
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &

SUDO_KEEPALIVE_PID=$!

cleanup() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}

trap cleanup EXIT

# -----------------------------
# ASUS hardware support
# -----------------------------

log "Installing asusctl"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$("/home/linuxbrew/.linuxbrew/bin/brew" shellenv)"
elif command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
else
    die "Homebrew installation completed but brew could not be found."
fi

if ! brew tap | grep -qx 'ubblue-os/homebrew-tap'; then
    brew tap ublue-os/homebrew-tap
fi

if ! brew list --cask 2>/dev/null | grep -qx 'asusctl-linux'; then
    brew trust --cask ublue-os/tap/asusctl-linux
    brew install --cask asusctl-linux
fi

# -----------------------------
# ASUS services
# -----------------------------

log "Enabling ASUS services"

sudo systemctl enable --now \
    asusd.service \
    asus-shutdown.service

systemctl --user daemon-reload

sudo udevadm control --reload
sudo udevadm trigger

# -----------------------------
# ASUS battery charge limit
# -----------------------------

log "Setting battery charge limit to ${BATTERY_LIMIT}%"

asusctl battery limit "$BATTERY_LIMIT"

# -----------------------------
# Finish
# -----------------------------

cat <<'EOF'

============================================================
ASUSCTL setup complete
============================================================

TODO:

1. Verify the ASUS battery limit:
       <homebrew location>/asusctl battery info

============================================================
EOF
