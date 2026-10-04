#!/bin/bash

fonts_pkgs=(
  fonts-kalam
  maplemono-nf-unhinted
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  ttf-architects-daughter
  ttf-comic-neue
  ttf-excalifont
  ttf-fantasque-nerd
  ttf-fira-code
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols-mono
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${fonts_pkgs[@]}"
