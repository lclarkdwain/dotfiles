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

# Steam and every lib32-* package live in [multilib], which Arch ships commented
# out. The repo header and its Include line are a pair -- uncommenting only the
# header leaves pacman with a repo it has no server for, so strip the '#' across
# the whole two-line block. The range start is anchored '^#\[multilib\]$' so the
# '#[multilib-testing]' section a few lines above is left commented.
if grep -q '^#\[multilib\]$' "$pacman_conf"; then
  sudo sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' "$pacman_conf"
  log ACTION "Enabled {MAGENTA}[multilib]{RESET} repository."
elif grep -q '^\[multilib\]$' "$pacman_conf"; then
  log ACTION "It seems {YELLOW}[multilib]{RESET} is already enabled, moving on..."
else
  log WARN "No {MAGENTA}[multilib]{RESET} section found in $pacman_conf. 32-bit packages (Steam, lib32-*) will not be installable."
fi

log ACTION "{MAGENTA}Pacman.conf{RESET} spicing up completed."

# updating pacman.conf
# -Syu, never a bare -Sy. Refreshing the sync database without upgrading leaves
# the box in Arch's partial-upgrade state: the databases advertise versions that
# are not installed, so the next `pacman -S <anything>` pulls a new library
# against old dependents and fails mid-transaction (or worse, succeeds). Adding
# a repo above makes this the first sync where that skew can appear, so the
# upgrade has to happen here rather than being left to a later script.
printf "\n%s - ${tput_colors[SKY_BLUE]}Synchronizing and upgrading packages${tput_colors[RESET]}\n" "${tput_colors[BLUE]}"
sudo pacman -Syu
