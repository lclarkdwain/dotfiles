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

DRY_RUN=0
COMMON_SCRIPTS_DIR="scripts/install-scripts/common"
SCRIPT_DIR=scripts/install-scripts/arch

execute_script() {
  local script="$1"
  local target_dir="${2:-$SCRIPT_DIR}"
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
        env "$script_path" "$@" || log ERROR "Script '$script' failed with exit code $?."
      fi
      log OK "Finished execution of {GREEN}$script{RESET}."
    else
      log ERROR "Failed to make script '$script' executable."
    fi
  else
    log ERROR "Script '$script' not found in '$script_directory'."
  fi
}

printf "\n%.0s" {1..1}
read -rp "This script is intended for fresh Arch Linux installations with no other desktop environment installed. Do you want to proceed? Type 'yes' to continue or anything else to abort [default: yes]: " response
response=${response,,}
response=${response:-yes}
if [[ "$response" != "yes" && "$response" != "y" ]]; then
  log INFO "Installation aborted by the user."
  exit 0
fi
printf "\n%.0s" {1..1}

execute_script "00-install-base.sh"
sleep 1
execute_script "install-aur.sh"
sleep 1

execute_script "01-install-core.sh"
sleep 1
execute_script "install-pipewire.sh"
sleep 1
execute_script "install-fonts.sh"
sleep 1
# execute_script "install-sway.sh"
# sleep 1

# execute_script "install-sddm.sh"
# sleep 1
# execute_script "install-vmware.sh"
# sleep 1
log INFO "Installing theme..."
sleep 1
log INFO "Installing xdg-desktop-portal..."
execute_script "install-xdp.sh"
sleep 1
# log INFO "Installing bluetooth..."
# execute_script "install-bluetooth.sh"
# sleep 1
log INFO "Installing file manager..."
sleep 1
log INFO "Installing sddm theme..."
sleep 1

execute_script "install-awscli.sh" "$COMMON_SCRIPTS_DIR"
execute_script "install-nvm.sh" "$COMMON_SCRIPTS_DIR"
execute_script "install-rust.sh" "$COMMON_SCRIPTS_DIR"
sleep 1
