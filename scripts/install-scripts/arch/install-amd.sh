#!/bin/bash

# AMD Radeon graphics. The kernel driver (amdgpu) and OpenGL + VA-API decode
# (radeonsi, inside mesa) need nothing beyond mesa; Vulkan is the separate
# vulkan-radeon ICD, without which Steam/Proton has no device to render on.
# On an AMD iGPU + NVIDIA dGPU laptop vulkan-radeon stays out, for the same
# reason install-intel.sh skips vulkan-intel: games would get a slower second
# Vulkan device to land on.

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

amd_pkgs=(
  mesa
  libva
)

if is_package_installed nvidia-utils; then
  log NOTE "NVIDIA userspace present; leaving out {GOLD}vulkan-radeon{RESET} so games stay on the NVIDIA GPU."
else
  amd_pkgs+=(vulkan-radeon)
fi

install_pacman_packages "${amd_pkgs[@]}"
