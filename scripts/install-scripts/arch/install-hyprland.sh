#!/bin/bash

hypr_pkgs=(
  hyprland
  hyprlock
  hypridle
  hyprsunset
  uwsm # session manager: "Hyprland (uwsm-managed)" in SDDM
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

had_uwsm=false
is_package_installed uwsm && had_uwsm=true

install_packages "${hypr_pkgs[@]}"

# Switch to the uwsm session once, when uwsm arrives; a later pick of plain Hyprland sticks
if [ "$had_uwsm" = false ]; then
  sddm_preselect_session /usr/share/wayland-sessions/hyprland-uwsm.desktop
fi
