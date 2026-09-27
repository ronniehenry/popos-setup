#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Embedded system development setup
# ============================================================

# -----------------------------
# Configuration
# -----------------------------

APT_PACKAGES=(
    # empty for now
)

FLATPAKS=(
    cc.arduino.IDE2
)


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
# Serial device access
# -----------------------------

if id -nG "$USER" | tr ' ' '\n' | grep -qx 'dialout'; then
    printf 'User %s is already a member of dialout.\n' "$USER"
else
    log "Adding $USER to the dialout group"
    sudo usermod -aG dialout "$USER"
    warn "Log out and back in (or reboot) for dialout membership to take effect."
fi

# -----------------------------
# Install APT packages
# -----------------------------

log "Installing APT packages"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    "${APT_PACKAGES[@]}"

# -----------------------------
# Flatpak
# -----------------------------

log "Installing Flatpak applications"

for app in "${FLATPAKS[@]}"; do
    if flatpak info "$app" >/dev/null 2>&1; then
        printf 'Already installed: %s\n' "$app"
    else
        flatpak install -y --noninteractive flathub "$app"
    fi
done
