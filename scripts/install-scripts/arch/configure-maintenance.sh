#!/bin/bash

# Periodic system upkeep timers. Both ship with their packages but are disabled.
#
#   paccache.timer        weekly; keeps the last 3 versions of each package in
#                         /var/cache/pacman/pkg instead of every version forever.
#   btrfs-scrub@-.timer   monthly; reads every block and checks it against its
#                         checksum. Corruption is otherwise found only when the
#                         file is next read, which may be after the last good
#                         backup has rotated out. One scrub covers the whole
#                         filesystem, so only the root mount needs a timer.
#
# fstrim.timer is deliberately left off: the btrfs mounts use discard=async,
# which already trims continuously.
#
# Undo: sudo systemctl disable --now paccache.timer btrfs-scrub@-.timer

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

sudo pacman -S --needed --noconfirm pacman-contrib
sudo systemctl enable --now paccache.timer
log SUCCESS "paccache.timer enabled"

if [ "$(findmnt -no FSTYPE /)" = "btrfs" ]; then
  sudo systemctl enable --now btrfs-scrub@-.timer
  log SUCCESS "btrfs-scrub@-.timer enabled (monthly)"
else
  log NOTE "Root is not btrfs; skipping the scrub timer"
fi
