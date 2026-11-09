#!/bin/bash

# btrfs snapshots with snapper, snap-pac and grub-btrfs.
#
#   root (@)      snap-pac takes a pre/post pair around every pacman
#                 transaction; plus a short hourly/daily timeline. /boot lives
#                 inside @, so the kernel and its modules are captured together.
#   home (@home)  hourly/daily timeline only, for recovering deleted or
#                 overwritten files.
#
# Excluded on purpose, because btrfs never descends into a nested or separately
# mounted subvolume: @games, @cache (/var/cache), @log (/var/log), and ~/.cache,
# which this script turns into its own subvolume so cache churn stays out of
# the home snapshots.
#
# Layout: each config's snapshots live in a top-level subvolume (@snapshots,
# @home_snapshots) mounted at .snapshots, NOT in the subvolume snapper nests
# inside @ by default. A nested one would be replaced along with @ on a
# restore, taking every snapshot with it.
#
# No btrfs quotas: they cost write performance, and the number and timeline
# limits below bound the snapshot count without them.
#
# --- Restoring ---------------------------------------------------------------
# GRUB boots `rootflags=subvol=@` by name, so `snapper rollback` (which sets
# the default subvolume) does not apply here. Restore by replacing @ instead:
#
#   snapper -c root list                              # pick snapshot N
#   sudo mount -o subvolid=5 <root device> /mnt
#   sudo mv /mnt/@ /mnt/@.broken
#   sudo btrfs subvolume snapshot /mnt/@snapshots/N/snapshot /mnt/@
#   sudo umount /mnt && reboot
#   # once the restored system is fine:
#   sudo btrfs subvolume delete /mnt/@.broken  (with the top level mounted again)
#
# If the system no longer boots, choose "Arch Linux snapshots" in the GRUB
# menu to boot a snapshot read-only, then run the steps above from a TTY. The
# graphical session may not start in a read-only snapshot. grub-btrfs's
# overlayfs hook would fix that, but it needs the busybox initramfs and this
# machine uses the systemd one.
#
# Single files: copy them back out of /.snapshots/N/snapshot/... or
# /home/.snapshots/N/snapshot/...
#
# Undo: sudo systemctl disable --now snapper-timeline.timer
#   snapper-cleanup.timer grub-btrfsd.service, delete the configs with
#   `sudo snapper -c <name> delete-config`, then remove the two .snapshots
#   fstab entries and the @snapshots / @home_snapshots subvolumes.

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

FSTAB="/etc/fstab"

if [ "$(findmnt -no FSTYPE /)" != "btrfs" ]; then
  log NOTE "Root filesystem is not btrfs; skipping snapshots"
  exit 0
fi

root_dev=$(findmnt -no SOURCE --nofsroot /)
fs_uuid=$(findmnt -no UUID /)
# Same options as the / mount, minus the subvolume selection
base_opts=$(findmnt -no OPTIONS / | tr ',' '\n' | grep -vE '^subvol(id)?=' | paste -sd,)

sudo pacman -S --needed --noconfirm snapper snap-pac inotify-tools
if pacman -Q grub >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm grub-btrfs
fi

# Subvolumes are created against the filesystem top level (subvolid=5), which
# is not mounted in normal operation.
top_mnt=$(mktemp -d)
cleanup() {
  mountpoint -q "$top_mnt" && sudo umount "$top_mnt"
  rmdir "$top_mnt" 2>/dev/null || true
}
trap cleanup EXIT
sudo mount -o subvolid=5 "$root_dev" "$top_mnt"

fstab_backup=""
add_fstab_entry() {
  local mnt=$1 subvol=$2 line
  grep -q "subvol=/${subvol}\b" "$FSTAB" && return 0

  if [ -z "$fstab_backup" ]; then
    fstab_backup="${FSTAB}.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp -a "$FSTAB" "$fstab_backup"
    log INFO "Backed up $FSTAB to $fstab_backup"
  fi

  line=$(printf 'UUID=%s\t%s\tbtrfs\t%s,subvol=/%s\t0 0' "$fs_uuid" "$mnt" "$base_opts" "$subvol")
  printf '\n# snapper: snapshots kept outside the subvolume they protect\n%s\n' "$line" |
    sudo tee -a "$FSTAB" >/dev/null

  # A malformed fstab fails the boot, not just this script
  if ! sudo findmnt --verify >/dev/null 2>&1; then
    log ERROR "findmnt --verify rejected $FSTAB; restoring $fstab_backup"
    sudo cp -a "$fstab_backup" "$FSTAB"
    exit 1
  fi
  sudo systemctl daemon-reload
  log SUCCESS "Added $mnt to $FSTAB"
}

# setup_config <name> <path> <top-level subvolume for its snapshots>
setup_config() {
  local name=$1 path=$2 subvol=$3
  local snapdir="${path%/}/.snapshots"

  if [ ! -f "/etc/snapper/configs/$name" ]; then
    # create-config refuses to run if .snapshots already exists
    if mountpoint -q "$snapdir"; then
      sudo umount "$snapdir"
    fi
    if [ -d "$snapdir" ]; then
      sudo rmdir "$snapdir" || {
        log ERROR "$snapdir exists and is not empty; move it aside and re-run"
        exit 1
      }
    fi
    sudo snapper -c "$name" create-config "$path"
    # Swap snapper's nested subvolume for the top-level one
    sudo btrfs subvolume delete "$snapdir"
    sudo mkdir "$snapdir"
    log SUCCESS "Created snapper config $name for $path"
  fi

  if [ ! -d "$top_mnt/$subvol" ]; then
    sudo btrfs subvolume create "$top_mnt/$subvol"
  fi

  add_fstab_entry "$snapdir" "$subvol"
  mountpoint -q "$snapdir" || sudo mount "$snapdir"
  if ! findmnt -no OPTIONS "$snapdir" | grep -q "subvol=/${subvol}\b"; then
    log ERROR "$snapdir is not mounted from $subvol; check $FSTAB"
    exit 1
  fi
  # Others cannot read through the snapshots; SYNC_ACL below grants wheel
  sudo chmod 750 "$snapdir"
}

setup_config root / @snapshots
setup_config home /home @home_snapshots

# Retention. snap-pac's pre/post pairs use the "number" cleanup algorithm; the
# timeline ones are pruned by snapper-cleanup.timer. ALLOW_GROUPS lets wheel
# run snapper without sudo.
sudo snapper -c root set-config \
  ALLOW_GROUPS=wheel SYNC_ACL=yes \
  NUMBER_CLEANUP=yes NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=10 \
  TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0
sudo snapper -c home set-config \
  ALLOW_GROUPS=wheel SYNC_ACL=yes \
  TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0
log SUCCESS "Retention: root 10 pacman pairs + 5 hourly + 7 daily; home 5 hourly + 7 daily"

# ~/.cache as its own subvolume, so it is left out of the home snapshots.
# Inode 256 marks a subvolume root.
cache="$HOME/.cache"
if [ "$(stat -c %i "$cache" 2>/dev/null)" != 256 ]; then
  log INFO "Turning $cache into a subvolume..."
  # Left behind only if an earlier run was interrupted
  rm -rf "$cache.old"
  if [ -e "$cache" ]; then
    # Apps with open files keep writing to the old copy until they restart
    mv "$cache" "$cache.old"
  fi
  sudo btrfs subvolume create "$cache"
  sudo chown "$(id -u):$(id -g)" "$cache"
  chmod 700 "$cache"
  if [ -d "$cache.old" ]; then
    # Reflinks share extents, so this copies no data. It is only cache, so
    # anything that fails to copy is dropped rather than stopping the script.
    cp -a --reflink=always "$cache.old/." "$cache/" 2>/dev/null ||
      log WARN "Some cache files were not copied; they will be regenerated"
    rm -rf "$cache.old"
  fi
  log SUCCESS "$cache is a subvolume"
fi

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
log SUCCESS "snapper timeline and cleanup timers enabled"

if pacman -Q grub-btrfs >/dev/null 2>&1; then
  # grub-btrfsd regenerates the snapshot submenu whenever /.snapshots changes
  sudo systemctl enable --now grub-btrfsd.service
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  log SUCCESS "GRUB lists snapshots under \"Arch Linux snapshots\""
fi

sudo snapper -c root create -c number -d "baseline after configure-snapshots.sh"
log SUCCESS "Baseline root snapshot taken"
snapper -c root list
