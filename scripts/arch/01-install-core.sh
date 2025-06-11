#!/bin/bash

core_pkgs=(
  bat
  brightnessctl
  fastfetch
  fd
  foot
  fzf
  grim
  imagemagick
  jq
  kitty
  lazygit
  luarocks
  mako
  neovim
  network-manager-applet
  ripgrep
  rofi-wayland
  stow
  waybar
  wezterm
  wget
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils
  xfce-polkit
  xorg-xwayland
  yad
  yazi
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${core_pkgs[@]}"
