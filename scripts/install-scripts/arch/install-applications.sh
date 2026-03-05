#!/bin/bash

# This is mostly from the AUR, so need to review the PKGBUILD files to ensure there are no malicious scripts being run.
# I also need to make sure that the packages are being installed from trusted sources.
post_pkgs=(
  zen-browser-bin
  google-chrome
  slack-desktop
  zoom
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${post_pkgs[@]}"
