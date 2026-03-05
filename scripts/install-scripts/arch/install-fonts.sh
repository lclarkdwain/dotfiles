#!/bin/bash

fonts_pkgs=(
  adobe-source-code-pro-fonts
  maplemono-nf-unhinted
  noto-fonts
  noto-fonts-emoji
  otf-font-awesome
  ttf-droid
  ttf-fantasque-nerd
  ttf-fira-code
  ttf-firacode-nerd
  ttf-font-awesome
  ttf-font-icons
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols-mono
  ttf-victor-mono
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${fonts_pkgs[@]}"
