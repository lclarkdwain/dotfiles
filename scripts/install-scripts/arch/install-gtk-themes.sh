#!/bin/bash

gtk_pkgs=(
  unzip
  gtk-engine-murrine
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# installing engine needed for gtk themes
install_packages "${gtk_pkgs[@]}"

# Check if the directory exists and delete it if present
if [ -d "GTK-themes-icons" ]; then
  echo "$NOTE GTK themes and Icons directory exist..deleting..." 2>&1 | log PIPE
  rm -rf "GTK-themes-icons" 2>&1 | log PIPE
fi

echo "$NOTE Cloning ${SKY_BLUE}GTK themes and Icons${RESET} repository..." 2>&1 | log PIPE
if git clone --depth=1 https://github.com/JaKooLit/GTK-themes-icons.git; then
  cd GTK-themes-icons
  chmod +x auto-extract.sh
  ./auto-extract.sh
  cd ..
  echo "$OK Extracted GTK Themes & Icons to ~/.icons & ~/.themes directories" 2>&1 | log PIPE
else
  echo "$ERROR Download failed for GTK themes and Icons.." 2>&1 | log PIPE
fi

printf "\n%.0s" {1..2}
