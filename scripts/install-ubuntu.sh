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
script_directory=scripts/install-scripts/ubuntu

execute_script() {
  local script="$1"
  shift
  local script_path="$script_directory/$script"

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
read -rp "Do you want to proceed? Type 'yes' to continue or anything else to abort [default: yes]: " response
response=${response,,}
response=${response:-yes}
if [[ "$response" != "yes" && "$response" != "y" ]]; then
  log INFO "Installation aborted by the user."
  exit 0
fi
printf "\n%.0s" {1..1}

# TODO: this is primarily used in WSL, so if native Ubuntu we might to include something like terminal, etc.
# Execute installation scripts in order
execute_script "install-updates.sh"
sleep 1

execute_script "install-nvm.sh"
sleep 1

execute_script "install-neovim.sh"
sleep 1

execute_script "install-rust.sh"
sleep 1

execute_script "install-go.sh"
sleep 1

execute_script "install-awscli.sh"
sleep 1

execute_script "configure-shell.sh"

printf "\n%.0s" {1..2}
log SUCCESS "Ubuntu development environment setup complete!"
printf "\n%.0s" {1..1}
log INFO "IMPORTANT: Please log out and log back in (or reboot) for all changes to take effect."
