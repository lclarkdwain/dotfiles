#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

# Failed installs are collected and reported on exit, failing the script
failed_pkgs=()
report_failed_pkgs() {
  local status=$?
  if [ ${#failed_pkgs[@]} -gt 0 ]; then
    log ERROR "Failed to install: {GOLD}${failed_pkgs[*]}{RESET}"
    [ "$status" -eq 0 ] && status=1
  fi
  exit "$status"
}
trap report_failed_pkgs EXIT

is_package_installed() {
  pacman -Q "$1" &>/dev/null
}

spinner() {
  local pid=$1
  local package_name=$2
  local total=$3
  local current=$4
  local action=$5 # "Installing" or "Uninstalling"
  local delay=0.1
  local spinstr='|/-\'
  local sudo_prompt_shown=false

  tput civis
  while ps -p "$pid" &>/dev/null; do
    if sudo -n true 2>/dev/null; then
      local temp=${spinstr#?}
      printf "\r${tput_colors[PURPLE]}[%d/%d]${tput_colors[RESET]} %s ${tput_colors[GOLD]}%s${tput_colors[RESET]} [%c]" \
        "$current" "$total" "$action" "$package_name" "$spinstr"
      spinstr=$temp${spinstr%"$temp"}
      sleep "$delay"
    else
      if ! $sudo_prompt_shown; then
        sudo_prompt_shown=true
      fi
      sleep "$delay"
    fi
  done

  printf "\r${tput_colors[GREEN]}[%d/%d]${tput_colors[RESET]} %s ${tput_colors[GOLD]}%s${tput_colors[RESET]} ${tput_colors[GREEN]}[✔]${tput_colors[RESET]} ... Done!%-20s \n" \
    "$current" "$total" "$action" "$package_name" ""
  tput cnorm
}

# Function to install a single package using pacman
install_pacman_package() {
  local force_reinstall=false
  local pkg=""
  for arg in "$@"; do
    if [[ "$arg" == "--force" ]]; then
      force_reinstall=true
    else
      pkg="$arg"
    fi
  done
  if [[ -z "$pkg" ]]; then
    log ERROR "No package specified."
    return 1
  fi
  if $force_reinstall || ! is_package_installed "$pkg"; then
    (set -o pipefail; sudo pacman -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
    pid=$!
    spinner "$pid" "$pkg" "1" "1" "Installing"
    wait "$pid" || {
      log ERROR "Error installing {GOLD}$pkg{RESET}."
      failed_pkgs+=("$pkg")
      return 1
    }
  else
    log "{BLUE}[1/1]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
  fi
}

# Function to install a single package using an AUR helper
install_aur_package() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  else
    log ERROR "No AUR helper found. Please install one (e.g., paru or yay)."
    return 1
  fi
  local force_reinstall=false
  local pkg=""
  for arg in "$@"; do
    if [[ "$arg" == "--force" ]]; then
      force_reinstall=true
    else
      pkg="$arg"
    fi
  done
  if [[ -z "$pkg" ]]; then
    log ERROR "No package specified."
    return 1
  fi
  if $force_reinstall || ! is_package_installed "$pkg"; then
    (set -o pipefail; $aur_helper -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
    pid=$!
    spinner "$pid" "$pkg" "1" "1" "Installing"
    wait "$pid" || {
      log ERROR "Error installing {GOLD}$pkg{RESET}."
      failed_pkgs+=("$pkg")
      return 1
    }
  else
    log "{BLUE}[1/1]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
  fi
}

# Function to install a single package (auto-detects AUR helper)
install_package() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  fi
  if [[ -n "$aur_helper" ]]; then
    log NOTE "AUR helper {MAGENTA}$aur_helper{RESET} detected. Installing package using AUR helper."
    install_aur_package "$@"
  else
    install_pacman_package "$@"
  fi
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
      (set -o pipefail; sudo pacman -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count" "Installing"
      wait "$pid" || {
        log ERROR "Error installing {GOLD}$pkg{RESET}."
        failed_pkgs+=("$pkg")
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
    fi
  done
}

install_aur_packages() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
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
      (set -o pipefail; $aur_helper -S --noconfirm "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count" "Installing"
      wait "$pid" || {
        log ERROR "Error installing {GOLD}$pkg{RESET}."
        failed_pkgs+=("$pkg")
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is already installed. Skipping."
    fi
  done
}

install_packages() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  fi
  if [[ -n "$aur_helper" ]]; then
    log NOTE "AUR helper {MAGENTA}$aur_helper{RESET} detected. Installing packages using AUR helper."
    install_aur_packages "$@"
  else
    install_pacman_packages "$@"
  fi
}

# Function to uninstall a single package using pacman
uninstall_pacman_package() {
  local cascade=false
  local nosave=false
  local pkg=""
  for arg in "$@"; do
    case "$arg" in
    --cascade) cascade=true ;;
    --nosave) nosave=true ;;
    *) pkg="$arg" ;;
    esac
  done
  if [[ -z "$pkg" ]]; then
    log ERROR "No package specified."
    return 1
  fi
  local pacman_flags="-R --noconfirm"
  $cascade && pacman_flags+="c"
  $nosave && pacman_flags+="n"
  if is_package_installed "$pkg"; then
    (sudo pacman $pacman_flags "$pkg" 2>&1 | log PIPE_NO_TERM) &
    pid=$!
    spinner "$pid" "$pkg" "1" "1" "Uninstalling"
    wait "$pid" || {
      log ERROR "Error uninstalling {GOLD}$pkg{RESET}."
      return 1
    }
  else
    log "{BLUE}[1/1]{RESET} Package {GOLD}$pkg{RESET} is not installed. Skipping."
  fi
}

# Function to uninstall a single package using an AUR helper
uninstall_aur_package() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  else
    log ERROR "No AUR helper found. Please install one (e.g., paru or yay)."
    return 1
  fi
  local cascade=false
  local nosave=false
  local pkg=""
  for arg in "$@"; do
    case "$arg" in
    --cascade) cascade=true ;;
    --nosave) nosave=true ;;
    *) pkg="$arg" ;;
    esac
  done
  if [[ -z "$pkg" ]]; then
    log ERROR "No package specified."
    return 1
  fi
  local pacman_flags="-R --noconfirm"
  $cascade && pacman_flags+="c"
  $nosave && pacman_flags+="n"
  if is_package_installed "$pkg"; then
    ($aur_helper $pacman_flags "$pkg" 2>&1 | log PIPE_NO_TERM) &
    pid=$!
    spinner "$pid" "$pkg" "1" "1" "Uninstalling"
    wait "$pid" || {
      log ERROR "Error uninstalling {GOLD}$pkg{RESET}."
      return 1
    }
  else
    log "{BLUE}[1/1]{RESET} Package {GOLD}$pkg{RESET} is not installed. Skipping."
  fi
}

# Function to uninstall a single package (auto-detects AUR helper)
uninstall_package() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  fi
  if [[ -n "$aur_helper" ]]; then
    log NOTE "AUR helper {MAGENTA}$aur_helper{RESET} detected. Uninstalling package using AUR helper."
    uninstall_aur_package "$@"
  else
    uninstall_pacman_package "$@"
  fi
}

# Function to uninstall packages using pacman
uninstall_pacman_packages() {
  local cascade=false
  local nosave=false
  local packages=()
  for arg in "$@"; do
    case "$arg" in
    --cascade) cascade=true ;;
    --nosave) nosave=true ;;
    *) packages+=("$arg") ;;
    esac
  done
  local pacman_flags="-R --noconfirm"
  $cascade && pacman_flags+="c"
  $nosave && pacman_flags+="n"
  local total=${#packages[@]}
  local count=0
  for pkg in "${packages[@]}"; do
    count=$((count + 1))
    if is_package_installed "$pkg"; then
      (sudo pacman $pacman_flags "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count" "Uninstalling"
      wait "$pid" || {
        log ERROR "Error uninstalling {GOLD}$pkg{RESET}."
        return 1
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is not installed. Skipping."
    fi
  done
}

uninstall_aur_packages() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  else
    log ERROR "No AUR helper found. Please install one (e.g., paru or yay)."
    return 1
  fi
  local cascade=false
  local nosave=false
  local packages=()
  for arg in "$@"; do
    case "$arg" in
    --cascade) cascade=true ;;
    --nosave) nosave=true ;;
    *) packages+=("$arg") ;;
    esac
  done
  local pacman_flags="-R --noconfirm"
  $cascade && pacman_flags+="c"
  $nosave && pacman_flags+="n"
  local total=${#packages[@]}
  local count=0
  for pkg in "${packages[@]}"; do
    count=$((count + 1))
    if is_package_installed "$pkg"; then
      ($aur_helper $pacman_flags "$pkg" 2>&1 | log PIPE_NO_TERM) &
      pid=$!
      spinner "$pid" "$pkg" "$total" "$count" "Uninstalling"
      wait "$pid" || {
        log ERROR "Error uninstalling {GOLD}$pkg{RESET}."
        return 1
      }
    else
      log "{BLUE}[$count/$total]{RESET} Package {GOLD}$pkg{RESET} is not installed. Skipping."
    fi
  done
}

uninstall_packages() {
  local aur_helper=""
  if paru --version &>/dev/null; then
    aur_helper="paru"
  elif yay --version &>/dev/null; then
    aur_helper="yay"
  fi
  if [[ -n "$aur_helper" ]]; then
    log NOTE "AUR helper {MAGENTA}$aur_helper{RESET} detected. Uninstalling packages using AUR helper."
    uninstall_aur_packages "$@"
  else
    uninstall_pacman_packages "$@"
  fi
}

# Preselect a session on the SDDM login screen, which opens on the last one used.
# With "if-unset", an existing choice is kept.
sddm_preselect_session() {
  local session="$1" mode="${2:-}" sddm_home state
  sddm_home=$(getent passwd sddm | cut -d: -f6)
  [ -n "$sddm_home" ] && [ -d "$sddm_home" ] && [ -f "$session" ] || return 0
  state="$sddm_home/state.conf"

  [ -f "$state" ] || sudo install -o sddm -g sddm -m 600 /dev/null "$state"
  if sudo grep -q '^Session=' "$state"; then
    [ "$mode" = "if-unset" ] && return 0
    sudo sed -i "s|^Session=.*|Session=$session|" "$state"
  elif sudo grep -q '^\[Last\]' "$state"; then
    sudo sed -i "/^\[Last\]/a Session=$session" "$state"
  else
    printf '[Last]\nSession=%s\n' "$session" | sudo tee -a "$state" >/dev/null
  fi
  log INFO "SDDM will preselect ${session##*/}"
}
