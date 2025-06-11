#!/bin/bash

bluetooth_pkgs=(
  blueman
  bluez
  bluez-utils
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${bluetooth_pkgs[@]}"
