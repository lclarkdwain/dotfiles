#!/bin/bash

# Dedicated btrfs subvolume for game data.
#
# Why games do not belong on @home:
#   - Copy-on-write turns every in-place write (shader caches, Proton prefix
#     registry churn, save scumming) into a fresh extent, fragmenting files that
#     are then read back in bulk at load time.
#   - compress=zstd:3 spends CPU on data that is already compressed. Game assets
#     are the single worst compression candidate on the disk.
#   - Once snapshots exist, game installs would be captured in them, which is
#     both pointless and enormous.
#
# The enforcement mechanism here is `chattr +C` on the empty mountpoint, NOT a
# nodatacow mount option. That is deliberate: btrfs applies most mount options
# filesystem-wide rather than per-subvolume, so a `nodatacow` in fstab on the
# second mount of an already-mounted filesystem is not reliably honoured and
# would create false confidence.
#
# This is observable, not theoretical: the compress=no below is IGNORED. The
# kernel reports compress=zstd:3 on this mount, inherited from the / mount of
# the same filesystem. It is left in the entry to document intent (and would
# become correct if btrfs ever honours it per-subvolume), but nothing should be
# read into its presence -- compression is actually avoided because NOCOW
# extents are never compressed. `chattr +C` on an empty directory is
# unambiguous -- files created inside it inherit NOCOW, and NOCOW extents are
# never compressed, so it covers the compression concern too. This script
# verifies that inheritance actually took effect rather than assuming it.
#
# NOCOW also disables checksums for these files. That is an accepted trade for
# re-downloadable game data, and is the reason this is a separate subvolume
# rather than an attribute on part of @home.
#
# Env overrides: DRY_RUN=1, GAMES_SUBVOL=@games, GAMES_MOUNT=$HOME/Games

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

DRY_RUN="${DRY_RUN:-0}"
GAMES_SUBVOL="${GAMES_SUBVOL:-@games}"
GAMES_MOUNT="${GAMES_MOUNT:-$HOME/Games}"
FSTAB="/etc/fstab"

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log INFO "{GOLD}dry-run:{RESET} $*"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

# Not applicable is not the same as failed. On a non-btrfs root there is simply
# nothing to do here, and exiting non-zero would make install-arch.sh log a
# spurious ERROR on every ext4/xfs machine.
if [ "$(findmnt -no FSTYPE /)" != "btrfs" ]; then
  log NOTE "Root filesystem is {YELLOW}$(findmnt -no FSTYPE /){RESET}, not btrfs. Skipping the dedicated games subvolume."
  exit 0
fi

root_dev=$(findmnt -no SOURCE --nofsroot /)
fs_uuid=$(findmnt -no UUID /)

if [ -z "$root_dev" ] || [ -z "$fs_uuid" ]; then
  log ERROR "Could not determine the root device or filesystem UUID."
  exit 1
fi

log INFO "Root filesystem: {SKY_BLUE}${root_dev}{RESET} (UUID ${fs_uuid})"
log INFO "Target: subvolume {MAGENTA}${GAMES_SUBVOL}{RESET} mounted at {MAGENTA}${GAMES_MOUNT}{RESET}"

# Idempotency: an existing fstab entry means this already ran.
if grep -q "subvol=/${GAMES_SUBVOL}\b" "$FSTAB"; then
  log OK "${FSTAB} already has an entry for {MAGENTA}${GAMES_SUBVOL}{RESET}; nothing to do."
  exit 0
fi

fstab_opts="rw,noatime,compress=no,ssd,discard=async,space_cache=v2,nofail,subvol=/${GAMES_SUBVOL}"
fstab_line=$(printf 'UUID=%s\t%s\tbtrfs\t%s\t0 0' "$fs_uuid" "$GAMES_MOUNT" "$fstab_opts")

printf "\n%.0s" {1..1}
log NOTE "The following line will be appended to ${FSTAB}:"
printf '\n  %s\n\n' "$fstab_line"

# ---------------------------------------------------------------------------
# Create the subvolume
# ---------------------------------------------------------------------------

# Subvolumes are created against the filesystem root (subvolid=5), which is not
# mounted anywhere in normal operation -- only @ and friends are. Mount it
# somewhere temporary just long enough to create @games.
top_mnt=$(mktemp -d)
cleanup() {
  mountpoint -q "$top_mnt" && sudo umount "$top_mnt"
  rmdir "$top_mnt" 2>/dev/null || true
}
trap cleanup EXIT

log INFO "Mounting the btrfs top level to create the subvolume..."
if [ "$DRY_RUN" -eq 1 ]; then
  log INFO "{GOLD}dry-run:{RESET} sudo mount -o subvolid=5 $root_dev $top_mnt"
  log INFO "{GOLD}dry-run:{RESET} sudo btrfs subvolume create $top_mnt/${GAMES_SUBVOL}"
else
  if ! sudo mount -o subvolid=5 "$root_dev" "$top_mnt"; then
    log ERROR "Could not mount the btrfs top level."
    exit 1
  fi
  if [ -d "$top_mnt/${GAMES_SUBVOL}" ]; then
    log WARN "Subvolume {MAGENTA}${GAMES_SUBVOL}{RESET} already exists; reusing it."
  elif sudo btrfs subvolume create "$top_mnt/${GAMES_SUBVOL}"; then
    log OK "Created subvolume {GREEN}${GAMES_SUBVOL}{RESET}."
  else
    log ERROR "Failed to create subvolume ${GAMES_SUBVOL}."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# fstab, with a validation gate
# ---------------------------------------------------------------------------

fstab_backup="${FSTAB}.bak.$(date +%Y%m%d%H%M%S)"
log INFO "Backing up ${FSTAB} to ${fstab_backup}..."
run sudo cp -a "$FSTAB" "$fstab_backup"

run mkdir -p "$GAMES_MOUNT"

if [ "$DRY_RUN" -eq 1 ]; then
  log INFO "{GOLD}dry-run:{RESET} append the line above to ${FSTAB}"
else
  printf '\n# games: no-CoW subvolume for the Steam library and Proton prefixes\n%s\n' "$fstab_line" |
    sudo tee -a "$FSTAB" >/dev/null

  # A malformed fstab is a failure to boot, not a failed command. Validate, and
  # roll back to the backup rather than leaving a broken file in place.
  if ! findmnt --verify --verbose >/dev/null 2>&1; then
    log ERROR "findmnt --verify rejected the new ${FSTAB}. Restoring the backup."
    sudo cp -a "$fstab_backup" "$FSTAB"
    findmnt --verify --verbose 2>&1 | tail -20
    exit 1
  fi
  log OK "${FSTAB} validates clean."

  sudo systemctl daemon-reload
  if ! sudo mount "$GAMES_MOUNT"; then
    log ERROR "Could not mount ${GAMES_MOUNT}. Restoring ${FSTAB} from backup."
    sudo cp -a "$fstab_backup" "$FSTAB"
    sudo systemctl daemon-reload
    exit 1
  fi
  log OK "Mounted {GREEN}${GAMES_MOUNT}{RESET}."
fi

# ---------------------------------------------------------------------------
# Ownership and NOCOW
# ---------------------------------------------------------------------------

# A freshly created subvolume's root is owned by root; the mount has to belong
# to the user before Steam can write to it.
run sudo chown "$(id -u):$(id -g)" "$GAMES_MOUNT"

# Must happen while the directory is empty -- +C is inherited by files created
# afterwards and does NOT apply retroactively.
run chattr +C "$GAMES_MOUNT"

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

if [ "$DRY_RUN" -eq 1 ]; then
  printf "\n%.0s" {1..1}
  log OK "Dry run complete. Nothing was changed."
  exit 0
fi

printf "\n%.0s" {1..1}
log INFO "Verifying..."

if ! findmnt -no OPTIONS "$GAMES_MOUNT" | grep -q "subvol=/${GAMES_SUBVOL}"; then
  log WARN "${GAMES_MOUNT} is mounted, but not from ${GAMES_SUBVOL}. Check ${FSTAB}."
else
  log OK "Mounted from {GREEN}${GAMES_SUBVOL}{RESET}: $(findmnt -no OPTIONS "$GAMES_MOUNT")"
fi

# Prove NOCOW inheritance actually works rather than trusting that chattr took.
probe="${GAMES_MOUNT}/.nocow-probe"
: >"$probe"
if lsattr "$probe" 2>/dev/null | awk '{print $1}' | grep -q C; then
  log OK "NOCOW inheritance confirmed: new files under ${GAMES_MOUNT} are created no-CoW."
else
  log WARN "New files under ${GAMES_MOUNT} are NOT inheriting NOCOW. Game data will be copy-on-write. Check: lsattr -d ${GAMES_MOUNT}"
fi
rm -f "$probe"

printf "\n%.0s" {1..1}
log NOTE "Point Steam at {SKY_BLUE}${GAMES_MOUNT}{RESET} via Steam > Settings > Storage > Add Drive, before installing any game."
