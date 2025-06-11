#!/bin/bash

fonts_pkgs=(
  maplemono-nf
  otf-font-awesome
  ttf-firacode-nerd
  ttf-font-awesome
  ttf-font-icons
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols-mono
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${fonts_pkgs[@]}"
