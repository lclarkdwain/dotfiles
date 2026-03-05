#!/bin/bash

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

pacman_conf="/etc/pacman.conf"

# Remove comments '#' from specific lines
lines_to_edit=(
  "Color"
  "CheckSpace"
  "VerbosePkgLists"
  "ParallelDownloads"
)

# Uncomment specified lines if they are commented out
for line in "${lines_to_edit[@]}"; do
  if grep -q "^#$line" "$pacman_conf"; then
    sudo sed -i "s/^#$line/$line/" "$pacman_conf"
    log ACTION "Uncommented: $line"
  else
    log ACTION "$line is already uncommented."
  fi
done

# Add "ILoveCandy" below ParallelDownloads if it doesn't exist
if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
  sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
  log ACTION "Added {MAGENTA}ILoveCandy{RESET} after {MAGENTA}ParallelDownloads{RESET}."
else
  log ACTION "It seems {YELLOW}ILoveCandy{RESET} already exists, moving on..."
fi

log ACTION "{MAGENTA}Pacman.conf{RESET} spicing up completed."

# updating pacman.conf
printf "\n%s - ${tput_colors[SKY_BLUE]}Synchronizing Pacman Repo${tput_colors[RESET]}\n" "${tput_colors[BLUE]}"
sudo pacman -Sy
