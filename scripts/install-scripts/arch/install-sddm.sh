#!/bin/bash

sddm_pkgs=(
  sddm
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${sddm_pkgs[@]}"
