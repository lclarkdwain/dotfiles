#!/bin/bash

pipewire_pkgs=(
  gst-plugin-pipewire
  libpulse
  pipewire
  pipewire-alsa
  pipewire-pulse
  sof-firmware
  wireplumber
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${pipewire_pkgs[@]}"

# log INFO "Enabling PipeWire services..."
# if ! systemctl --user is-enabled pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1 | log PIPE; then
#   systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1 | log PIPE
# fi
# log OK "PipeWire services enabled."
