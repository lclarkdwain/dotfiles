#!/bin/bash

quickshell_pkgs=(
  qt6-5compat
  quickshell
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}Quick Shell ${RESET} for Desktop Overview \n" "${NOTE}"

install_packages "${quickshell_pkgs[@]}"

printf "\n%.0s" {1..1}
