#!/bin/bash

set -euo pipefail

if ! source "$(dirname "$(realpath "$0")")/../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

command_exists() {
  command -v "$1" &>/dev/null
}

install_paru() {
  local helper="$1"

  log INFO "Installing {MAGENTA}$helper{RESET}..."
  if ! command_exists git; then
    log ERROR "git is not installed. Please install git first."
    exit 1
  fi

  # Create a temporary directory for the installation
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  git clone "https://aur.archlinux.org/$helper.git" "$temp_dir/$helper"
  cd "$temp_dir/$helper"
  if makepkg -si --noconfirm 2>&1 | log PIPE; then
    log SUCCESS "Successfully installed {GREEN}$helper{RESET}."
  else
    log ERROR "Failed to install {RED}$helper{RESET}."
    exit 1
  fi
}

uninstall_paru() {
  local helper="$1"

  log INFO "Removing {MAGENTA}$helper{RESET}..."
  if command_exists pacman; then
    if sudo pacman -Rns --noconfirm "$helper"; then
      log SUCCESS "Successfully removed {MAGENTA}$helper{RESET}."
    else
      log WARN "{MAGENTA}$helper{RESET} is not installed."
    fi
  else
    log ERROR "pacman is not available. Cannot uninstall {MAGENTA}$helper{RESET}."
    exit 1
  fi
}

main() {
  local helper="paru-bin"

  log INFO "Checking if {MAGENTA}$helper{RESET} is already installed..."
  if command_exists paru; then
    log INFO "{MAGENTA}$helper{RESET} is already installed."
    read -rp "Do you want to reinstall or switch to a different helper? (reinstall/skip) [skip]: " choice
    choice=${choice:-skip}
    case "$choice" in
    reinstall)
      uninstall_paru "$helper"
      install_paru "$helper"
      ;;
    skip)
      log INFO "Skipping installation."
      exit 0
      ;;
    *)
      log ERROR "Invalid choice. Exiting."
      exit 1
      ;;
    esac
  else
    log INFO "{MAGENTA}$helper{RESET} is not installed."
    install_paru "$helper"
  fi

  log WARN "Performing full system upgrade..."
  if paru -Syu; then
    log SUCCESS "System upgrade completed successfully."
  else
    log ERROR "System upgrade failed. Please check the logs and resolve any issues."
    exit 1
  fi
}

main "$@"
