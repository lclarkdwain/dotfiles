#!/bin/bash

clear

printf "\n%.0s" {1..2}
echo -e "\e[35m
.-.. -.-. -..    -.. --- - ...
\e[0m"
printf "\n%.0s" {1..1}

if ! source "$(dirname "$(realpath "$0")")/utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

# TODO: essential checks before installations

printf "\n%.0s" {1..1}
read -rp "This script is intended for fresh Arch Linux installations with no other desktop environment installed. Do you want to proceed? Type 'yes' to continue or anything else to abort [default: yes]: " response
response=${response,,}
response=${response:-yes}
if [[ "$response" != "yes" && "$response" != "y" ]]; then
  log INFO "Installation aborted by the user."
  exit 0
fi

# TODO: essential utilities before installations
sleep 1
printf "\n%.0s" {1..1}

# install pciutils if detected not installed. Necessary for detecting GPU
if ! pacman -Qs pciutils >/dev/null; then
  log INFO "pciutils is not installed. Installing..."
  sudo pacman -S --noconfirm pciutils
  printf "\n%.0s" {1..1}
fi

DRY_RUN=0
SCRIPTS_DIR=scripts/install-scripts/arch
REPO_DIR=$(dirname "$(dirname "$(realpath "$0")")")
failed_scripts=()

execute_script() {
  local script="$1"
  local target_dir="${2:-$SCRIPTS_DIR}"
  local script_path="$target_dir/$script"

  printf "\n%.0s" {1..1}
  log INFO "Starting execution of {RED}$script{RESET}..."
  printf "\n%.0s" {1..1}

  if [ -f "$script_path" ]; then
    chmod +x "$script_path"
    if [ -x "$script_path" ]; then
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log INFO "{GOLD}Dry-run mode:{RESET} Skipping execution of '$script'."
      else
        if env "$script_path" "$@"; then
          log OK "Finished execution of {GREEN}$script{RESET}."
        else
          log ERROR "Script '$script' failed with exit code $?."
          failed_scripts+=("$script")
        fi
      fi
    else
      log ERROR "Failed to make script '$script' executable."
    fi
  else
    log ERROR "Script '$script' not found in '$target_dir'."
  fi
}

# List of services to check for active login managers
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Function to check if any login services are active
check_services_running() {
  active_services=() # Array to store active services
  for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
      active_services+=("$svc")
    fi
  done

  if [ ${#active_services[@]} -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

if check_services_running; then
  active_list=$(printf "%s\n" "${active_services[@]}")
  log WARNING "The following login manager(s) are active:\n\n$active_list\n\nIf you want to install SDDM and SDDM theme, stop and disable the active services aboce, reboot before running this script again."
fi

# Check if NVIDIA GPU is detected
nvidia_detected=false
if lspci | grep -i "nvidia" &>/dev/null; then
  nvidia_detected=true
  log NOTE "NVIDIA GPU detected in your system.\n\nNOTE: The script will install nvidia-dkms, nvidia-utils, and nvidia-settings."
fi

# Add 'input_group' option if user is not in input group
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
  input_group_detected=true
  log INFO "You are not currently in the input group.\n\nAdding you to the input group might be necessary for the Waybar keyboard-state functionality."
fi

# The gaming stack is opt-in. It pulls Steam plus the entire 32-bit graphics
# userspace, which is a large amount of disk and completely unwanted on a
# machine that will never run a game. Asked here, with the other detections, so
# the whole run stays unattended after this point.
gaming_wanted=false
printf "\n%.0s" {1..1}
read -rp "Install the gaming stack (Steam, GameMode, MangoHud, gamescope)? [y/N]: " gaming_response
gaming_response=${gaming_response,,}
if [[ "$gaming_response" == "y" || "$gaming_response" == "yes" ]]; then
  gaming_wanted=true
  log INFO "Gaming stack will be installed."
else
  log INFO "Skipping the gaming stack."
fi

scx_wanted=false
printf "\n%.0s" {1..1}
read -rp "Enable scx_lavd, a latency-focused CPU scheduler? It replaces the kernel's scheduler system-wide. [y/N]: " scx_response
scx_response=${scx_response,,}
if [[ "$scx_response" == "y" || "$scx_response" == "yes" ]]; then
  scx_wanted=true
  log INFO "scx_lavd will be enabled."
else
  log INFO "Skipping scx_lavd."
fi

# Lenovo laptops only
conservation_wanted=false
if grep -qs 'Long_Life' /sys/class/power_supply/BAT*/charge_types ||
  compgen -G "/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode" >/dev/null; then
  printf "\n%.0s" {1..1}
  read -rp "Enable battery conservation mode? Charging stops at about 80% to extend battery life. [y/N]: " conservation_response
  conservation_response=${conservation_response,,}
  if [[ "$conservation_response" == "y" || "$conservation_response" == "yes" ]]; then
    conservation_wanted=true
    log INFO "Battery conservation mode will be enabled."
  else
    log INFO "Skipping battery conservation mode."
  fi
fi

printf "\n%.0s" {1..1}

# Base. configure-pacman.sh first: its -Syu refreshes the sync databases
execute_script "configure-pacman.sh"
sleep 1
execute_script "00-install-base.sh"
sleep 1
execute_script "configure-timesync.sh"
sleep 1

# Link first: `make link` rm -rf's tracked ~/.config dirs that later scripts create
log INFO "Linking the dotfiles before installing..."
sudo pacman -S --needed --noconfirm stow
if ! make -C "$REPO_DIR" --no-print-directory link; then
  log ERROR "make link failed. Resolve it and re-run; continuing would install into unlinked config directories."
  exit 1
fi
sleep 1

# AUR
execute_script "install-aur.sh"
sleep 1

# DE Core
execute_script "01-install-core.sh"
sleep 1
execute_script "configure-polkit.sh"
sleep 1
execute_script "install-pipewire.sh"
sleep 1
execute_script "install-fonts.sh"
sleep 1
execute_script "install-hyprland.sh"
sleep 1
# execute_script "install-sway.sh"
# sleep 1

if check_services_running; then
  active_list=$(printf "%s\n" "${active_services[@]}")
  log ERROR "One of the following login services is running:\n$active_list\n\nPlease stop & disable it or DO not choose SDDM."
  exec "$0"
else
  log INFO "Installing and configuring {SKY_BLUE}SDDM...{RESET}"
  execute_script "install-sddm.sh"
fi
sleep 1

# configure-nouveau.sh first, so the blacklist lands in the rebuilt initramfs
if [ "$nvidia_detected" == "true" ]; then
  execute_script "configure-nouveau.sh"
  execute_script "install-nvidia.sh"
fi
sleep 1

execute_script "install-gtk-themes.sh"
sleep 1

if [ "$input_group_detected" == "true" ]; then
  execute_script "configure-input-group.sh"
fi
sleep 1

execute_script "install-quickshell.sh"
sleep 1

# After install-aur.sh: quickshell-git comes from the AUR
execute_script "install-caelestia.sh"
sleep 1

execute_script "install-xdp.sh"
sleep 1
execute_script "install-bluetooth.sh"
sleep 1
execute_script "install-thunar.sh"
execute_script "configure-thunar-default.sh"
sleep 1
execute_script "install-sddm-theme.sh"
sleep 1
execute_script "install-zsh.sh"
sleep 1
# TODO: Laptop utilities (power profiles, control center, etc.)
execute_script "configure-dots.sh"
sleep 1

execute_script "install-zram.sh"
sleep 1

if [ "$conservation_wanted" == "true" ]; then
  execute_script "configure-battery-conservation.sh"
  sleep 1
fi

if [ "$scx_wanted" == "true" ]; then
  execute_script "install-scx.sh"
  sleep 1
fi

# Runs after install-nvidia.sh so lib32-nvidia-utils can be matched against the
# already-installed nvidia-utils, and after configure-pacman.sh has enabled
# [multilib] -- install-gaming.sh hard-fails on either being absent rather than
# installing something half-working.
if [ "$gaming_wanted" == "true" ]; then
  execute_script "install-gaming.sh"
  sleep 1
  execute_script "configure-games-subvol.sh"
  sleep 1
fi

COMMON_SCRIPTS_DIR="scripts/install-scripts/common"
execute_script "install-awscli.sh" "$COMMON_SCRIPTS_DIR"
execute_script "install-nvm.sh" "$COMMON_SCRIPTS_DIR"
execute_script "install-rust.sh" "$COMMON_SCRIPTS_DIR"
execute_script "install-rtk.sh" "$COMMON_SCRIPTS_DIR"
sleep 1

execute_script "install-applications.sh"
sleep 1
# After install-applications.sh: it needs the browser
execute_script "configure-granted.sh" "$COMMON_SCRIPTS_DIR"
sleep 1
execute_script "install-wezterm.sh"
sleep 1

execute_script "02-post-install.sh"

if [ ${#failed_scripts[@]} -gt 0 ]; then
  printf "\n%.0s" {1..1}
  log ERROR "These scripts failed; check ${REPO_DIR}/logs/ and re-run them:\n\n$(printf '%s\n' "${failed_scripts[@]}")"
fi

printf "\n%.0s" {1..1}

# if pacman -Q hyprland &>/dev/null || pacman -Q hyprland-git &>/dev/null; then
#   printf "\n ${tput_colors[GREEN]} 👌 Hyprland is installed. However, some essential packages may not be installed. Please see above!"
#   printf "\n${tput_colors[CYAN]} Ignore this message if it states ${tput_colors[YELLOW]}All essential packages${tput_colors[RESET]} are installed as per above\n"
#   sleep 2
#   printf "\n%.0s" {1..2}
#
#   printf "\n${tput_colors[NOTE]} You can start Hyprland by typing ${tput_colors[SKY_BLUE]}Hyprland${tput_colors[RESET]} (IF SDDM is not installed) (note the capital H!).\n"
#   printf "\n${tput_colors[NOTE]} However, it is ${tput_colors[YELLOW]}highly recommended to reboot${tput_colors[RESET]} your system.\n\n"
#
#   while true; do
#     log ACTION "Would you like to reboot now? (y/n): "
#     read HYP
#     HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')
#
#     if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
#       log INFO "Rebooting now..."
#       systemctl reboot
#       break
#     elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
#       log OK "You chose NOT to reboot"
#       printf "\n%.0s" {1..1}
#       # Check if NVIDIA GPU is present
#       if lspci | grep -i "nvidia" &>/dev/null; then
#         log INFO "However {YELLOW}NVIDIA GPU{RESET} detected. Reminder that you must REBOOT your SYSTEM..."
#         printf "\n%.0s" {1..1}
#       fi
#       break
#     else
#       log WARN "Invalid response. Please answer with 'y' or 'n'."
#     fi
#   done
# else
#   # Print error message if neither package is installed
#   printf "\n${tput_colors[YELLOW]} Hyprland is NOT installed. Please check logs/ directory..."
#   printf "\n%.0s" {1..3}
#   exit 1
# fi

printf "\n%.0s" {1..2}
