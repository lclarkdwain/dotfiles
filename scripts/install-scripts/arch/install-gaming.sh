#!/bin/bash

# Gaming stack: Steam plus the tooling that makes it behave on Hyprland/NVIDIA.
#
# All but ProtonPlus are in official repos, so this deliberately uses
# install_pacman_packages rather than install_packages. The latter auto-detects
# paru and would route the whole set through the AUR helper for no benefit --
# slower, and it drags AUR trust decisions into a path that does not need them.

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

if ! pacman-conf --repo-list 2>/dev/null | grep -qx multilib; then
  log ERROR "The {MAGENTA}[multilib]{RESET} repository is not enabled. Run {GOLD}configure-pacman.sh{RESET} first -- Steam and every lib32-* package are unresolvable without it."
  exit 1
fi

if ! is_package_installed nvidia-utils; then
  log ERROR "{GOLD}nvidia-utils{RESET} is not installed. Run {GOLD}install-nvidia.sh{RESET} first so the 32-bit driver can be matched against it."
  exit 1
fi

# Installing new packages onto a system with pending upgrades is Arch's
# partial-upgrade hazard: pacman resolves the new package against current repo
# versions, pulling updated libraries in next to un-upgraded dependents. Enabling
# [multilib] makes this materially more likely, since every lib32-* package
# arrives at repo-current versions with no installed counterpart to anchor them.
# Upgrade first, always, rather than discovering it as a failed transaction.
pending=$(pacman -Qu 2>/dev/null | wc -l)
if [ "$pending" -gt 0 ]; then
  log WARN "$pending package(s) are pending upgrade. Installing the gaming stack on top of that risks a partial upgrade."
  log INFO "Running a full system upgrade first..."
  if ! sudo pacman -Syu; then
    log ERROR "System upgrade failed. Resolve it before installing the gaming stack."
    exit 1
  fi
else
  log OK "System is fully upgraded; safe to install new packages."
fi

# ---------------------------------------------------------------------------
# Stage 1 - 32-bit graphics driver, installed BEFORE steam
# ---------------------------------------------------------------------------

# Ordering here is load-bearing, not cosmetic. steam depends on the virtual
# packages lib32-vulkan-driver and lib32-opengl-driver, and each has many
# providers (lib32-vulkan-nouveau, lib32-mesa, lib32-vulkan-intel, ...).
# `pacman --noconfirm` never prompts to disambiguate -- it silently takes the
# first provider it finds, which on an NVIDIA box can install the nouveau Vulkan
# ICD alongside the proprietary driver and leave Steam unable to create a Vulkan
# device. Installing lib32-nvidia-utils up front satisfies both virtuals, so the
# steam transaction has nothing left to guess at.
driver_pkgs32=(
  lib32-nvidia-utils
  lib32-vulkan-icd-loader
)

log INFO "Installing the 32-bit NVIDIA userspace first, to pin provider resolution for Steam..."
install_pacman_packages "${driver_pkgs32[@]}"

# The 32- and 64-bit halves of the NVIDIA userspace are one driver split across
# two packages. A version skew between them breaks 32-bit Vulkan in ways that
# surface as an unexplained in-game crash rather than a package error, so say so
# loudly here instead of letting it be discovered later.
nvidia_ver=$(pacman -Q nvidia-utils 2>/dev/null | awk '{print $2}')
nvidia_ver32=$(pacman -Q lib32-nvidia-utils 2>/dev/null | awk '{print $2}')
if [[ "$nvidia_ver" != "$nvidia_ver32" ]]; then
  log WARN "NVIDIA userspace version skew: {GOLD}nvidia-utils $nvidia_ver{RESET} vs {GOLD}lib32-nvidia-utils $nvidia_ver32{RESET}. 32-bit Vulkan will misbehave until both come from the same driver release."
else
  log OK "NVIDIA userspace matched at {GREEN}${nvidia_ver}{RESET} across 64-bit and 32-bit."
fi

# ---------------------------------------------------------------------------
# Stage 2 - the gaming stack proper
# ---------------------------------------------------------------------------

gaming_pkgs=(
  steam
  # Feral GameMode. gamemoded is D-Bus activated as a user service, so there is
  # nothing to systemctl enable. The lib32 half is required for 32-bit titles to
  # be able to make the request at all.
  gamemode
  lib32-gamemode
  # Both halves needed for the same reason: the overlay is a Vulkan layer and
  # has to match the bitness of the game it is layering onto.
  mangohud
  lib32-mangohud
  gamescope
  # vulkaninfo/vkcube, for verifying the stack without launching a game.
  vulkan-tools
  protontricks
)

install_pacman_packages "${gaming_pkgs[@]}"

# ---------------------------------------------------------------------------
# gamemode group
# ---------------------------------------------------------------------------

# Group membership gates nearly everything gamemode does, via two separate
# mechanisms:
#
#   1. /etc/security/limits.d/10-gamemode.conf ships "@gamemode - nice -10",
#      which is what permits the renice in .config/gamemode.ini.
#   2. /usr/share/polkit-1/actions/com.feralinteractive.GameMode.policy sets
#      allow_any, allow_inactive AND allow_active to "no" for every helper. The
#      ONLY grant path is gamemode.rules, which returns YES solely when
#      subject.isInGroup("gamemode"). That covers cpugovctl (the CPU governor),
#      gpuclockctl, cpucorectl and procsysctl.
#
# So without this group the daemon starts, accepts clients and reports success,
# but the governor is never switched and the renice never applies -- only ioprio
# and the screensaver inhibit still work. Verified with `gamemoded -t`, which
# fails "Verifying CPU governor setting" and "Verifying renice" until the user
# is in the group AND has logged back in (the running user session caches its
# group list, so usermod alone does not take effect).
if getent group gamemode >/dev/null 2>&1; then
  log OK "{MAGENTA}gamemode{RESET} group exists."
else
  log NOTE "{MAGENTA}gamemode{RESET} group does not exist. Creating it..."
  sudo groupadd gamemode
  log OK "{MAGENTA}gamemode{RESET} group created."
fi

if id -nG "$(whoami)" | tr ' ' '\n' | grep -qx gamemode; then
  log OK "User is already in the {MAGENTA}gamemode{RESET} group."
else
  sudo usermod -aG gamemode "$(whoami)"
  log OK "Added user to the {MAGENTA}gamemode{RESET} group. {YELLOW}Takes effect on next login.{RESET}"
fi

# MangoHud won't create its log folder. Not in ~/Games: that gets mounted over.
mkdir -p "$HOME/mangologs"

# ProtonPlus manages GE-Proton/proton-cachyos; the only AUR package here.
if command -v paru &>/dev/null || command -v yay &>/dev/null; then
  install_aur_package protonplus || log WARN "{GOLD}protonplus{RESET} did not install. Steam's own Proton builds are unaffected."
else
  log NOTE "No AUR helper found; skipping {GOLD}protonplus{RESET}. Run install-aur.sh, then re-run this script."
fi

# Arch ships ntsync as a module nothing autoloads; Proton uses it if present.
ntsync_conf="/etc/modules-load.d/ntsync.conf"
if ! modinfo ntsync &>/dev/null; then
  log NOTE "This kernel has no ntsync module; skipping."
else
  if [ -f "$ntsync_conf" ]; then
    log OK "$ntsync_conf already exists."
  else
    echo ntsync | sudo tee "$ntsync_conf" >/dev/null
    log OK "Wrote $ntsync_conf so ntsync loads at boot."
  fi

  if [ ! -c /dev/ntsync ] && ! sudo modprobe ntsync; then
    log WARN "Could not load ntsync now; it will load on next boot."
  fi
fi

# Steam Deck community sysctls against memory compaction/reclaim stutter.
gaming_sysctl="/etc/sysctl.d/99-gaming.conf"
if [ -f "$gaming_sysctl" ]; then
  log WARN "$gaming_sysctl already exists; leaving it untouched."
else
  sudo tee "$gaming_sysctl" >/dev/null <<'CONF'
vm.compaction_proactiveness = 0
vm.watermark_boost_factor = 1
vm.page_lock_unfairness = 1
CONF
  sudo sysctl --system >/dev/null
  log OK "Memory tuning applied: compaction_proactiveness=$(sysctl -n vm.compaction_proactiveness), watermark_boost_factor=$(sysctl -n vm.watermark_boost_factor), page_lock_unfairness=$(sysctl -n vm.page_lock_unfairness)"
fi

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

printf "\n%.0s" {1..1}
log INFO "Verifying the gaming stack..."

missing=()
for pkg in "${driver_pkgs32[@]}" "${gaming_pkgs[@]}"; do
  is_package_installed "$pkg" || missing+=("$pkg")
done

if [ ${#missing[@]} -ne 0 ]; then
  log WARN "The following gaming packages did not install:"
  for pkg in "${missing[@]}"; do
    log WARNING "$pkg"
  done
else
  log OK "All gaming packages installed."
fi

# Catch the exact failure the Stage 1 ordering exists to prevent. If a competing
# 32-bit ICD is present next to lib32-nvidia-utils, the loader can hand a game
# the wrong driver.
stray_icd=$(pacman -Qq 2>/dev/null | grep -E '^lib32-vulkan-(nouveau|intel|radeon|swrast)$' || true)
if [[ -n "$stray_icd" ]]; then
  log WARN "A competing 32-bit Vulkan driver is installed alongside the NVIDIA one:\n$stray_icd\nThis usually means provider resolution picked the wrong ICD. Remove it unless another GPU in this machine needs it."
else
  log OK "No competing 32-bit Vulkan ICD present."
fi

if [ -c /dev/ntsync ]; then
  log OK "/dev/ntsync is present; Proton can use ntsync."
elif modinfo ntsync &>/dev/null; then
  log WARN "/dev/ntsync is missing, so Proton falls back to wineserver sync. Check: sudo modprobe ntsync"
fi

printf "\n%.0s" {1..1}
log NOTE "Verify the runtime stack from inside a graphical session with {SKY_BLUE}vulkaninfo --summary{RESET} and {SKY_BLUE}mangohud vkcube{RESET}."
log NOTE "Manual steps no script can do (BIOS, Steam settings, per-game options) are tracked in {SKY_BLUE}docs/gaming.md{RESET}."
