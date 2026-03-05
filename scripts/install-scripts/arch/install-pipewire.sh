#!/bin/bash

pipewire_pkgs=(
  gst-plugin-pipewire
  libpulse
  pipewire
  pipewire-alsa
  pipewire-audio
  pipewire-pulse
  sof-firmware
  wireplumber
)

pipewire_2_pkgs=(
  pipewire_pulse
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Disabling pulseaudio to avoid conflicts and logging output
echo -e "${NOTE} Disabling pulseaudio to avoid conflicts..."
systemctl --user enable --now pulseaudio.socket pulseaudio.service 2>&1 | log PIPE || true

# Pipewire
echo -e "${NOTE} Installing ${SKY_BLUE}Pipewire${RESET} Packages..."
install_packages "${pipewire_pkgs[@]}"
install_packages "${pipewire_2_pkgs[@]}"

echo -e "${NOTE} Activating Pipewire Services..."
# Redirect systemctl output to log file
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1 | log PIPE
systemctl --user enable --now pipewire.service 2>&1 | log PIPE

echo -e "\n${OK} Pipewire Installation and services setup complete!" 2>&1 | log PIPE
