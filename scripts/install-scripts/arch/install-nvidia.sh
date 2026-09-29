#!/bin/bash

# global_fn.sh is sourced first because the driver-flavour check below needs
# is_package_installed().
source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# nvidia-open-dkms and nvidia-dkms provide the same kernel modules and CONFLICT
# with each other, so hardcoding one uninstalls the other mid-run on a machine
# that already made the opposite choice. Honour whatever is installed. For a
# fresh install default to the open modules: nvidia-utils 580+ dropped
# pre-Turing support entirely, so every card this driver branch still serves is
# one the open modules also support.
if is_package_installed nvidia-open-dkms; then
  nvidia_driver_pkg="nvidia-open-dkms"
elif is_package_installed nvidia-dkms; then
  nvidia_driver_pkg="nvidia-dkms"
else
  nvidia_driver_pkg="nvidia-open-dkms"
fi
log INFO "Using {SKY_BLUE}${nvidia_driver_pkg}{RESET} for the NVIDIA kernel modules."

nvidia_pkgs=(
  "$nvidia_driver_pkg"
  nvidia-settings
  nvidia-utils
  libva
  libva-nvidia-driver
)

# 32-bit userspace driver, needed by Proton/Wine and older native titles. Only
# resolvable once [multilib] is live (configure-pacman.sh enables it), so this
# is guarded rather than allowed to fail the whole NVIDIA step on a box that
# does not want 32-bit support.
nvidia_lib32_pkgs=(
  lib32-nvidia-utils
  lib32-vulkan-icd-loader
)

# nvidia stuff
printf "${YELLOW} Checking for other hyprland packages and remove if any..${RESET}\n"
if pacman -Qs hyprland >/dev/null; then
  printf "${YELLOW} Hyprland detected. removing to install Hyprland from official repo...${RESET}\n"
  for hyprnvi in hyprland-git hyprland-nvidia hyprland-nvidia-git hyprland-nvidia-hidpi-git; do
    sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | log PIPE || true
  done
fi

# Install additional Nvidia packages
printf "${YELLOW} Installing ${SKY_BLUE}Nvidia Packages and Linux headers${RESET}...\n"
for krnl in $(cat /usr/lib/modules/*/pkgbase); do
  for NVIDIA in "${krnl}-headers" "${nvidia_pkgs[@]}"; do
    install_package "$NVIDIA"
  done
done

if pacman-conf --repo-list 2>/dev/null | grep -qx multilib; then
  log INFO "{MAGENTA}[multilib]{RESET} is enabled - installing 32-bit NVIDIA userspace..."
  for pkg32 in "${nvidia_lib32_pkgs[@]}"; do
    install_package "$pkg32"
  done
else
  log WARN "{MAGENTA}[multilib]{RESET} is not enabled; skipping {GOLD}lib32-nvidia-utils{RESET}. Steam and Proton will not run until configure-pacman.sh enables it."
fi

# Laptops only: nvidia-powerd runs Dynamic Boost. Without it the GPU stays at its
# base power limit (35 W instead of 76 W on an RTX 5050 laptop). nvidia-utils
# ships it disabled; on a desktop card it has nothing to do.
if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
  log INFO "Laptop detected - enabling {SKY_BLUE}nvidia-powerd{RESET} (Dynamic Boost)..."
  (set -o pipefail; sudo systemctl enable --now nvidia-powerd.service 2>&1 | log PIPE) ||
    log WARN "Could not enable nvidia-powerd; run: sudo systemctl enable --now nvidia-powerd"
fi

# The package counting as installed does not mean the module was built: pacman
# registers it before the dkms hook compiles, so an interrupted build (reboot,
# killed run) leaves no nvidia.ko while install_package skips it on every rerun.
# Verify each kernel actually has the module and build it in the foreground if
# not, so a rerun repairs the damage instead of silently booting without it.
for kdir in /usr/lib/modules/*/; do
  [[ -f "${kdir}pkgbase" ]] || continue
  kver=$(basename "$kdir")
  if modinfo -k "$kver" nvidia &>/dev/null; then
    log OK "NVIDIA module present for {GOLD}$kver{RESET}."
  else
    log WARN "NVIDIA module missing for {GOLD}$kver{RESET}; building it now. This takes several minutes, do not interrupt it."
    if ! sudo dkms autoinstall -k "$kver"; then
      log ERROR "dkms failed to build the NVIDIA module for {GOLD}$kver{RESET}. See /var/lib/dkms/nvidia/*/build/make.log."
      exit 1
    fi
  fi
done

# Check if the Nvidia modules are already added in mkinitcpio.conf and add if not
if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
  echo "Nvidia modules already included in /etc/mkinitcpio.conf" 2>&1 | log PIPE
else
  sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | log PIPE
  echo "${OK} Nvidia modules added in /etc/mkinitcpio.conf"
fi

printf "\n%.0s" {1..1}
printf "${INFO} Rebuilding ${YELLOW}Initramfs${RESET}...\n" 2>&1 | log PIPE
sudo mkinitcpio -P 2>&1 | log PIPE

printf "\n%.0s" {1..1}

# Additional Nvidia steps
NVEA="/etc/modprobe.d/nvidia.conf"
if [ -f "$NVEA" ]; then
  printf "${INFO} Seems like ${YELLOW}nvidia_drm modeset=1 fbdev=1${RESET} is already added in your system..moving on."
  printf "\n"
else
  printf "\n"
  printf "${YELLOW} Adding options to $NVEA..."
  sudo echo -e "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | log PIPE
  printf "\n"
fi

# Additional for GRUB users
if [ -f /etc/default/grub ]; then
  printf "${INFO} ${YELLOW}GRUB${RESET} bootloader detected\n" 2>&1 | log PIPE

  # Check if nvidia-drm.modeset=1 is present
  if ! sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
    printf "${OK} nvidia-drm.modeset=1 added to /etc/default/grub\n" 2>&1 | log PIPE
  fi

  # Check if nvidia_drm.fbdev=1 is present
  if ! sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
    sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia_drm.fbdev=1"/' /etc/default/grub
    printf "${OK} nvidia_drm.fbdev=1 added to /etc/default/grub\n" 2>&1 | log PIPE
  fi

  # Regenerate GRUB configuration
  if sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub || sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    printf "${INFO} ${YELLOW}GRUB${RESET} configuration regenerated\n" 2>&1 | log PIPE
  fi

  printf "${OK} Additional steps for ${YELLOW}GRUB${RESET} completed\n" 2>&1 | log PIPE
fi

# Additional for systemd-boot users
if [ -f /boot/loader/loader.conf ]; then
  printf "${INFO} ${YELLOW}systemd-boot${RESET} bootloader detected\n" 2>&1 | log PIPE

  backup_count=$(find /boot/loader/entries/ -type f -name "*.conf.bak" | wc -l)
  conf_count=$(find /boot/loader/entries/ -type f -name "*.conf" | wc -l)

  if [ "$backup_count" -ne "$conf_count" ]; then
    find /boot/loader/entries/ -type f -name "*.conf" | while read imgconf; do
      # Backup conf
      sudo cp "$imgconf" "$imgconf.bak"
      printf "${INFO} Backup created for systemd-boot loader: %s\n" "$imgconf" 2>&1 | log PIPE

      # Clean up options and update with NVIDIA settings
      sdopt=$(grep -w "^options" "$imgconf" | sed 's/\b nvidia-drm.modeset=[^ ]*\b//g' | sed 's/\b nvidia_drm.fbdev=[^ ]*\b//g')
      sudo sed -i "/^options/c${sdopt} nvidia-drm.modeset=1 nvidia_drm.fbdev=1" "$imgconf" 2>&1 | log PIPE
    done

    printf "${OK} Additional steps for ${YELLOW}systemd-boot${RESET} completed\n" 2>&1 | log PIPE
  else
    printf "${NOTE} ${YELLOW}systemd-boot${RESET} is already configured...\n" 2>&1 | log PIPE
  fi
fi

printf "\n%.0s" {1..2}
