#!/bin/bash

# quickshell-git, not quickshell: caelestia-shell requires the git build and the
# two conflict, so installing the extra/ release here only to replace it later
# costs a second build. `qs -c overview` runs on the git build unchanged.
quickshell_pkgs=(
  qt6-5compat
  quickshell-git
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}Quick Shell ${RESET} for Desktop Overview and the caelestia shell \n" "${NOTE}"

install_packages "${quickshell_pkgs[@]}"

printf "\n%.0s" {1..1}
