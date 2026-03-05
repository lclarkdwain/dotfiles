#!/bin/bash

sddm_pkgs=(
  qt6-declarative
  qt6-svg
  qt6-virtualkeyboard
  qt6-multimedia-ffmpeg
  qt5-quickcontrols2
  sddm
)

disable_pkgs=(
  lightdm
  gdm3
  gdm
  lxdm
  lxdm-gtk3
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Install SDDM and SDDM theme
printf "${NOTE} Installing sddm and dependencies........\n"
install_packages "${sddm_pkgs[@]}"

printf "\n%.0s" {1..1}

# Check if other login managers installed and disabling its service before enabling sddm
for login_manager in "${disable_pkgs[@]}"; do
  if pacman -Qs "$login_manager" >/dev/null 2>&1; then
    sudo systemctl disable "$login_manager.service" 2>&1 | log PIPE
    echo "$login_manager disabled." 2>&1 | log PIPE
  fi
done

# Double check with systemctl
for manager in "${disable_pkgs[@]}"; do
  if systemctl is-active --quiet "$manager" >/dev/null 2>&1; then
    echo "$manager is active, disabling it..." 2>&1 | log PIPE
    sudo systemctl disable "$manager" --now 2>&1 | log PIPE
  fi
done

printf "\n%.0s" {1..1}
printf "${INFO} Activating sddm service........\n"
sudo systemctl enable sddm

wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && {
  printf "$CAT - $wayland_sessions_dir not found, creating...\n"
  sudo mkdir "$wayland_sessions_dir" 2>&1 | log PIPE
}

printf "\n%.0s" {1..2}
