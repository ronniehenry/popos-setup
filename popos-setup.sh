#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Pop!_OS initial setup
# ============================================================

# -----------------------------
# Configuration
# -----------------------------

BATTERY_LIMIT=80

APT_PACKAGES=(
    # C/C++ development
    build-essential
    gdb
    valgrind
    cmake
    ninja-build
    meson
    clang
    clang-format
    clang-tidy

    # Python development
    python3
    python-is-python3
    python3-venv
    python3-pip
    pipx

    # General development
    git
    curl
    wget
    gpg
    apt-transport-https

    # Shell
    zsh

    # System
    ufw
)

FLATPAKS=(
    com.transmissionbt.Transmission
    org.videolan.VLC
    org.gimp.GIMP
    org.inkscape.Inkscape
    org.kde.kdenlive
    fr.handbrake.ghb
    org.strawberrymusicplayer.strawberry
    org.localsend.localsend_app
    io.github.getnf.embellish
    com.valvesoftware.Steam
    com.visualstudio.code
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
# Update system
# -----------------------------

log "Updating package lists"

sudo apt update

log "Upgrading installed packages"

sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

log "Removing unused packages"

sudo apt autoremove -y

# -----------------------------
# Install base packages
# -----------------------------

log "Installing base packages"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    "${APT_PACKAGES[@]}"

# -----------------------------
# Firewall
# -----------------------------

log "Enabling firewall"

sudo ufw --force enable

# -----------------------------
# Multimedia support
# -----------------------------

log "Installing restricted multimedia codecs"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ubuntu-restricted-extras

# -----------------------------
# DVD playback
# -----------------------------

log "Installing DVD playback support"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    libdvd-pkg

log "Configuring libdvdcss"

sudo dpkg-reconfigure -f noninteractive libdvd-pkg

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
systemctl --user enable --now asusd-user.service

sudo udevadm control --reload
sudo udevadm trigger

# -----------------------------
# ASUS battery charge limit
# -----------------------------

log "Setting battery charge limit to ${BATTERY_LIMIT}%"

asusctl battery limit "$BATTERY_LIMIT"

# -----------------------------
# Flatpak
# -----------------------------

log "Configuring Flathub"

if ! flatpak remote-list | awk '{print $1}' | grep -qx 'flathub'; then
    flatpak remote-add --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
fi

log "Installing Flatpak applications"

for app in "${FLATPAKS[@]}"; do
    if flatpak info "$app" >/dev/null 2>&1; then
        printf 'Already installed: %s\n' "$app"
    else
        flatpak install -y --noninteractive flathub "$app"
    fi
done

# -----------------------------
# Zsh
# -----------------------------

log "Configuring Zsh"

if ! command -v zsh >/dev/null 2>&1; then
    sudo apt install -y zsh
fi

# -----------------------------
# Oh My Zsh
# -----------------------------

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh"

    RUNZSH=no \
    CHSH=no \
    KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    printf 'Oh My Zsh already installed.\n'
fi

# -----------------------------
# Default shell
# -----------------------------

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$(command -v zsh)" ]]; then
    log "Changing default shell to Zsh"
    chsh -s "$(command -v zsh)"
else
    printf 'Zsh is already the default shell.\n'
fi

# -----------------------------
# Finish
# -----------------------------

cat <<'EOF'

============================================================
Pop!_OS setup complete
============================================================

TODO:

1. Check and apply firmware updates:
       sudo fwupdmgr get-updates
       sudo fwupdmgr update

2. Set your machine hostname if desired:
       sudo hostnamectl set-hostname <hostname>

3. Reboot the computer.

4. Verify the ASUS battery limit:
       asusctl battery info

5. Open a new terminal session to start using Zsh.

============================================================
EOF
