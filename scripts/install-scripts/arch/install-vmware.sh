#!/bin/bash

vmware_pkgs=(
  gtkmm3
  mesa
  mesa-utils
  open-vm-tools
  xf86-input-libinput
  xf86-input-vmmouse
  xf86-video-vmware
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${vmware_pkgs[@]}"
