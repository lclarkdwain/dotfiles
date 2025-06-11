#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

is_package_installed() {
  pacman -Q "$1" &>/dev/null
}

spinner() {
  local pid=$1
  local package_name=$2
  local total=$3
  local current=$4
  local delay=0.1
  local spinstr='|/-\'
  local sudo_prompt_shown=false

  tput civis
  while ps -p "$pid" &>/dev/null; do
    if sudo -n true 2>/dev/null; then
      local temp=${spinstr#?}
      printf "\r${tput_colors[PURPLE]}[%d/%d]${tput_colors[RESET]} Installing ${tput_colors[GOLD]}%s${tput_colors[RESET]} [%c]" \
        "$current" "$total" "$package_name" "$spinstr"
      spinstr=$temp${spinstr%"$temp"}
      sleep "$delay"
    else
      if ! $sudo_prompt_shown; then
        # echo "[!] Waiting for password..."
        sudo_prompt_shown=true
      fi
      sleep "$delay"
    fi
  done

  printf "\r${tput_colors[GREEN]}[%d/%d]${tput_colors[RESET]} Installing ${tput_colors[GOLD]}%s${tput_colors[RESET]} ${tput_colors[GREEN]}[✔]${tput_colors[RESET]} ... Done!%-20s \n" \
    "$current" "$total" "$package_name" ""
  tput cnorm
}

# Function to install packages using pacman
install_pacman_packages() {
  local force_reinstall=false
  local packages=()

  # Parse arguments
  for arg in "$@"; do
    if [[ "$arg" == "--force" ]]; then
      force_reinstall=true
    else
      packages+=("$arg")
    fi
  done

  local total=${#packages[@]}
  local count=0
  for pkg in "${packages[@]}"; do
    count=$((count + 1))
    if $force_reinstall || ! is_package_installed "$pkg"; then
      # (sudo pacman -S --noconfirm "$pkg" &>/dev/null) &
      (sudo pacman -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count"
      wait "$pid" || {
        log ERROR "Error installing {GOLD}$pkg{RESET}."
        return 1
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
    fi
  done
}

install_aur_packages() {
  local aur_helper=""
  if command -v paru &>/dev/null; then
    aur_helper="paru"
  elif command -v yay &>/dev/null; then
    aur_helper="yay"
  else
    log ERROR "No AUR helper found. Please install one (e.g., paru or yay)."
    return 1
  fi

  local force_reinstall=false
  local packages=()

  for arg in "$@"; do
    if [[ "$arg" == "--force" ]]; then
      force_reinstall=true
    else
      packages+=("$arg")
    fi
  done

  local total=${#packages[@]}
  local count=0
  for pkg in "${packages[@]}"; do
    count=$((count + 1))
    if $force_reinstall || ! is_package_installed "$pkg"; then
      ($aur_helper -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count"
      wait "$pid" || {
        log ERROR "Error installing {GOLD}$pkg{RESET}."
        return 1
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
    fi
  done
}

install_packages() {
  local aur_helper=""
  if command -v paru &>/dev/null; then
    aur_helper="paru"
  elif command -v yay &>/dev/null; then
    aur_helper="yay"
  fi

  if [[ -n "$aur_helper" ]]; then
    log NOTE "AUR helper {MAGENTA}$aur_helper{RESET} detected. Installing packages using AUR helper."
    install_aur_packages "$@"
  else
    install_pacman_packages "$@"
  fi
}
