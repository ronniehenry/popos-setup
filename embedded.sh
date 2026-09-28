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

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx 'dialout'; then
    log "Adding $USER to the dialout group"
    sudo usermod -aG dialout "$USER"
fi

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx 'plugdev'; then
    log "Adding $USER to the plugdev group"
    sudo usermod -aG plugdev "$USER"
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

# -----------------------------
# Install extensions for VSCode
# -----------------------------

if ! dpkg -s code >/dev/null 2>&1; then
    printf 'VSCode is NOT installed. Skipping extension installation...\n'
else
    # Install PlatformIO extension for VSCode
    if code --list-extensions | grep "platformio.platformio-ide"; then
        printf 'VSCode PlatformIO extension is already installed.\n'
    else
        log "Installing VSCode PlatformIO extension"
        code --install-extension platformio.platformio-ide
    fi
fi

# -----------------------------
# Finish
# -----------------------------

cat <<'EOF'

============================================================
Embedded development setup complete
============================================================

TODO:

1. Verify the added groups to the user

2. Verify the apps installed

3. Check if the extensions are present in VSCode

============================================================
EOF

