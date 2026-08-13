#!/bin/bash

# Desktop environment core packages installations

extras=(
  fd
  foot
  fzf
  jq
  lazygit
  less
  luarocks
  neovim
  ripgrep
  stow
)

core_pkgs=(
  #aylurs-gtk-shell
  bc
  cliphist
  curl
  grim
  gvfs
  gvfs-mtp
  hyprpolkitagent
  imagemagick
  inxi
  jq
  kitty
  kvantum
  libspng
  nano
  network-manager-applet
  pamixer
  pavucontrol
  libpulse
  playerctl
  python-requests
  python-pyquery
  qt5ct
  qt-style-kvantum
  qt6ct
  qt6-svg
  qt6-style-kvantum
  rofi
  slurp
  swappy
  swaync
  awww
  unzip # needed later
  wallust
  # waybar-git, not waybar: the released 0.15.0 sends legacy hyprlang dispatch
  # strings over IPC, which Hyprland's Lua config parser rejects -- clicking a
  # workspace in the bar does nothing. master translates them via
  # buildLuaDispatch() (hl.dsp.focus). Provides/conflicts waybar, so the
  # pacman -Qi waybar check in 02-post-install.sh still resolves.
  # Revert to plain `waybar` once the fix lands in a tagged release.
  waybar-git
  waybar-weather
  wget
  wl-clipboard
  wlogout
  xfce-polkit
  xdg-user-dirs
  xdg-utils
  yad
)

core_optional_pkgs=(
  brightnessctl
  btop
  cava
  loupe
  fastfetch
  gnome-system-monitor
  mousepad
  mpv
  mpv-mpris
  nvtop
  nwg-look
  nwg-displays
  pacman-contrib
  qalculate-gtk
  yt-dlp
)

uninstall_pkgs=(
  aylurs-gtk-shell
  dunst
  cachyos-hyprland-settings
  mako
  wallust-git
  rofi-lbonn-wayland
  rofi-lbonn-wayland-git
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

uninstall_packages "${uninstall_pkgs[@]}"
printf "\n%.0s" {1..1}

install_packages "${core_pkgs[@]}"
printf "\n%.0s" {1..1}
install_packages "${core_optional_pkgs[@]}"
printf "\n%.0s" {1..1}
install_packages "${extras[@]}"

# Ensure hyprpolkitagent user service is enabled and running
if systemctl --user list-unit-files 2>/dev/null | grep -q '^hyprpolkitagent\.service'; then
  if ! systemctl --user is-enabled --quiet hyprpolkitagent 2>/dev/null; then
    systemctl --user enable hyprpolkitagent 2>&1 | log PIPE || true
  fi
  if ! systemctl --user is-active --quiet hyprpolkitagent 2>/dev/null; then
    systemctl --user start hyprpolkitagent 2>&1 | log PIPE || true
  fi
fi
