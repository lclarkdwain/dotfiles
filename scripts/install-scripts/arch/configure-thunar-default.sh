#!/bin/bash

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

printf "${INFO} Setting ${SKY_BLUE}Thunar${RESET} as default file manager...\n"

xdg-mime default thunar.desktop inode/directory
xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search
echo "${OK} ${MAGENTA}Thunar${RESET} is now set as the default file manager." | log PIPE

printf "\n%.0s" {1..2}
