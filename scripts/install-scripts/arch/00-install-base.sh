#!/bin/bash

base_pkgs=(
  base-devel
  archlinux-keyring
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_pacman_packages "${base_pkgs[@]}"
