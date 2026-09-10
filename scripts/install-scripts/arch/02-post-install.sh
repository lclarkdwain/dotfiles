#!/bin/bash

packages=(
  cliphist
  kvantum
  rofi-wayland
  imagemagick
  swaync
  awww
  wallust
  waybar
  wl-clipboard
  wlogout
  kitty
  hypridle
  hyprlock
  hyprland
)

# Gaming stack. Checked only when steam is present, because install-arch.sh
# makes these opt-in -- listing them unconditionally would report a "missing"
# package on every machine that deliberately declined them. When steam IS
# installed, a gap here is worth catching: a game launching without its 32-bit
# layers fails as a confusing crash rather than an obvious missing package.
gaming_packages=(
  gamemode
  lib32-gamemode
  mangohud
  lib32-mangohud
  gamescope
  lib32-vulkan-icd-loader
  protontricks
)

# Local packages that should be in /usr/local/bin/
local_pkgs_installed=(

)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

printf "\n%s - Final Check if all ${SKY_BLUE}Essential packages${RESET} were installed \n" "${NOTE}"
# Initialize an empty array to hold missing packages
missing=()
local_missing=()

# Function to check if a packages are installed using pacman
is_installed_pacman() {
  pacman -Qi "$1" &>/dev/null
}

# Loop through each package
for pkg in "${packages[@]}"; do
  # Check if the packages are installed
  if ! is_installed_pacman "$pkg"; then
    missing+=("$pkg")
  fi
done

# Gaming stack, only if it was opted into
if is_installed_pacman steam; then
  for pkg in "${gaming_packages[@]}"; do
    if ! is_installed_pacman "$pkg"; then
      missing+=("$pkg")
    fi
  done

  # The 32-bit driver is vendor-specific, so only expect the NVIDIA one on a
  # machine that actually installed the NVIDIA driver.
  if is_installed_pacman nvidia-utils && ! is_installed_pacman lib32-nvidia-utils; then
    missing+=("lib32-nvidia-utils")
  fi

  if modinfo ntsync &>/dev/null && [ ! -c /dev/ntsync ]; then
    log WARN "/dev/ntsync is missing; Proton cannot use ntsync. Re-run install-gaming.sh."
  fi
fi

# scx_lavd, if opted into (install-scx.sh writes this file)
if [ -f /etc/scx_loader/config.toml ]; then
  for pkg in scx-scheds scx-tools; do
    if ! is_installed_pacman "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if [ "$(cat /sys/kernel/sched_ext/state 2>/dev/null)" != "enabled" ]; then
    log WARN "scx_lavd is configured but sched_ext is not active. Check: systemctl status scx_loader"
  fi
fi

# Check for local packages
for pkg1 in "${local_pkgs_installed[@]}"; do
  if ! [ -f "/usr/local/bin/$pkg1" ]; then
    local_missing+=("$pkg1")
  fi
done

# Log missing packages
if [ ${#missing[@]} -eq 0 ] && [ ${#local_missing[@]} -eq 0 ]; then
  log OK "GREAT! All {YELLOW}essential packages{RESET} have been successfully installed."
else
  if [ ${#missing[@]} -ne 0 ]; then
    log WARN "The following packages are not installed and will be logged:"
    for pkg in "${missing[@]}"; do
      log WARNING "$pkg"
      log "$pkg"
    done
  fi

  if [ ${#local_missing[@]} -ne 0 ]; then
    log WARN "The following local packages are missing from /usr/local/bin/ and will be logged:"
    for pkg1 in "${local_missing[@]}"; do
      log WARNING "$pkg1 is not installed. Can't find it in /usr/local/bin/"
      log "$pkg1"
    done
  fi

  log NOTE "Missing packages logged at $(date)"
fi

# Check hyprpolkitagent user service status
if systemctl --user list-unit-files 2>/dev/null | grep -q '^hyprpolkitagent\.service'; then
  if systemctl --user is-active --quiet hyprpolkitagent 2>/dev/null; then
    echo "${OK} hyprpolkitagent user service is running." | log PIPE
  else
    echo "${WARN} hyprpolkitagent user service is not running." | log PIPE
  fi
fi
