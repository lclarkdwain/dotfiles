#!/bin/bash

wezterm_pkgs=(
  wezterm-git
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

printf "\n%s - Installing ${SKY_BLUE}WezTerm (git)${RESET} \n" "${NOTE}"

# Conflicts with wezterm-git, and --noconfirm won't remove it
if is_package_installed wezterm; then
  log INFO "Removing stable {GOLD}wezterm{RESET} to replace it with {GOLD}wezterm-git{RESET}..."
  sudo pacman -R --noconfirm wezterm 2>&1 | log PIPE
fi

install_packages "${wezterm_pkgs[@]}"

printf "\n%.0s" {1..1}
