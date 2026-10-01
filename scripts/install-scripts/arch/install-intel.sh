#!/bin/bash

# Intel iGPU video decode (VA-API), for machines where the iGPU renders the desktop.
# vulkan-intel stays out: on a hybrid laptop it gives games a second, slower Vulkan device to land on.

intel_pkgs=(
  libva
  intel-media-driver
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_pacman_packages "${intel_pkgs[@]}"
