#!/bin/bash

thunar_pkgs=(
  thunar
  thunar-volman
  tumbler
  ffmpegthumbnailer
  thunar-archive-plugin
  xarchiver
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Thunar
printf "${INFO} Installing ${SKY_BLUE}Thunar${RESET} Packages...\n"
install_packages "${thunar_pkgs[@]}"

printf "\n%.0s" {1..1}

# Check for existing configs and copy if does not exist (Thunar is tracked in .config)
for DIR1 in gtk-3.0 xfce4; do
  DIRPATH=~/.config/$DIR1
  if [ -d "$DIRPATH" ]; then
    echo -e "${NOTE} Config for ${MAGENTA}$DIR1${RESET} found, no need to copy." 2>&1 | log PIPE
  else
    echo -e "${NOTE} Config for ${YELLOW}$DIR1${RESET} not found, copying from assets." 2>&1 | log PIPE
    cp -r assets/$DIR1 ~/.config/ && echo "${OK} Copy $DIR1 completed!" || echo "${ERROR} Failed to copy $DIR1 config files." 2>&1 | log PIPE
  fi
done

printf "\n%.0s" {1..2}
