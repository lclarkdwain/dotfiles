#!/bin/bash

clear
# Relative to .config/waybar, so the tracked symlinks carry no /home/<user> path.
waybar_style="style/Wallust-Personal.css"
waybar_config="configs/TOP-Personal"
waybar_config_laptop="configs/TOP-Default-Laptop"

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

dot_scripts_dir=$(realpath "${source_dir}/../../dot-scripts")

# shellcheck source=../../dot-scripts/apps.sh
[[ -f "${dot_scripts_dir}/apps.sh" ]] && source "${dot_scripts_dir}/apps.sh"

# shellcheck source=../../dot-scripts/detect.sh
[[ -f "${dot_scripts_dir}/detect.sh" ]] && source "${dot_scripts_dir}/detect.sh"

# shellcheck source=../../dot-scripts/prompts.sh
[[ -f "${dot_scripts_dir}/prompts.sh" ]] && source "${dot_scripts_dir}/prompts.sh"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
  echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......."
  printf "\n%.0s" {1..2}
  exit 1
fi

# Function to print colorful text
print_color() {
  # Use %b for the message to interpret backslash escapes like \n, \t, etc.
  printf "%b%b%b\n" "$1" "$2" "$RESET"
}

# Check /etc/os-release for Ubuntu or Debian and warn about Hyprland version requirement
if grep -iqE '^(ID_LIKE|ID)=.*(ubuntu|debian)' /etc/os-release >/dev/null 2>&1; then
  printf "\n%.0s" {1..1}
  print_color $WARNING "\nThese Dotfiles are only supported on Hyprland v0.50 or greater. Do not install on older versions of Hyprland.\n"
  while true; do
    echo -n "${CAT} Do you want to continue anyway? (y/N): "
    read _continue
    _continue=$(echo "${_continue}" | tr '[:upper:]' '[:lower:]')
    case "${_continue}" in
    y | yes)
      echo "${NOTE} Proceeding on Ubuntu/Debian by user confirmation."
      break
      ;;
    n | no | "")
      printf "\n%.0s" {1..1}
      echo "${INFO} Aborting per user choice. No changes made."
      printf "\n%.0s" {1..1}
      exit 1
      ;;
    *)
      echo "${WARN} Please answer 'y' or 'n'."
      ;;
    esac
  done
fi

# update home directories
xdg-user-dirs-update 2>&1 | log PIPE || true

printf "\n%.0s" {1..1}

layout=$(prompt_detect_layout)
prompt_keyboard_layout "$layout"

enable_asusctl

printf "\n%.0s" {1..1}

resolution=""
while true; do
  echo "${INFO} Select monitor resolution for scaling:"
  echo "  1) < 1440p   (lower DPI; smaller displays)"
  echo "  2) ≥ 1440p   (default; 1440p/2k/4k)"
  echo -n "${CAT} Enter the number of your choice (1 or 2): "
  read -r choice
  case "$choice" in
  1)
    resolution="< 1440p"
    break
    ;;
  2)
    resolution="≥ 1440p"
    break
    ;;
  *) echo "${ERROR} Invalid choice. Please enter 1 or 2." ;;
  esac
done
echo "${OK} You have chosen $resolution resolution." 2>&1 | log PIPE

# Apply a sed script only if it changes the file. `sed -i` rewrites a file even
# when nothing matches, so a re-run with the same answer would still touch it.
sed_if_changed() {
  local file="$1" script="$2" tmp
  [ -f "$file" ] || return 0
  tmp=$(mktemp)
  sed "$script" "$file" >"$tmp"
  if cmp -s "$file" "$tmp"; then
    echo "${NOTE} $file already at this preset; skipping." 2>&1 | log PIPE
  else
    cat "$tmp" >"$file"
    echo "${OK} Updated $file." 2>&1 | log PIPE
  fi
  rm -f "$tmp"
}

# rofi fonts are deliberately not scaled: the committed 15/13 is kept at every
# resolution, including 1080p.
if [ "$resolution" == "< 1440p" ]; then
  sed_if_changed .config/kitty/kitty.conf 's/font_size 16.0/font_size 14.0/'
else
  sed_if_changed .config/kitty/kitty.conf 's/font_size 14.0/font_size 16.0/'
fi

printf "\n%.0s" {1..1}
prompt_clock_12h
printf "\n%.0s" {1..1}
printf "\n%.0s" {1..1}

# Define the target directory for rofi themes
rofi_DIR="$HOME/.local/share/rofi/themes"

if [ ! -d "$rofi_DIR" ]; then
  mkdir -p "$rofi_DIR"
fi
if [ -d "$HOME/.config/rofi/themes" ]; then
  if [ -z "$(ls -A $HOME/.config/rofi/themes)" ]; then
    echo '/* Dummy Rofi theme */' >"$HOME/.config/rofi/themes/dummy.rasi"
  fi
  ln -snf "$HOME/.config/rofi/themes/"* "$HOME/.local/share/rofi/themes/"
  # Delete the dummy file if it was created
  if [ -f "$HOME/.config/rofi/themes/dummy.rasi" ]; then
    rm "$HOME/.config/rofi/themes/dummy.rasi"
  fi
fi

printf "\n%.0s" {1..1}

# wallpaper stuff
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
mkdir -p "$PICTURES_DIR/wallpapers"
if cp -r wallpapers "$PICTURES_DIR/"; then
  echo "${OK} Some ${MAGENTA}wallpapers${RESET} copied successfully!" | log PIPE
else
  echo "${ERROR} Failed to copy some ${YELLOW}wallpapers${RESET}" | log PIPE
fi

# Reload user systemd and ensure hyprpolkitagent is enabled/running
if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user list-unit-files 2>/dev/null | grep -q '^hyprpolkitagent\.service'; then
    if ! pgrep -u "$UID" -f 'xfce-polkit|polkit-gnome-authentication-agent-1|polkit-kde-authentication-agent-1|hyprpolkitagent' >/dev/null 2>&1; then
      systemctl --user daemon-reload 2>&1 | log PIPE || true
      systemctl --user enable hyprpolkitagent 2>&1 | log PIPE || true
      systemctl --user start hyprpolkitagent 2>&1 | log PIPE || true
    else
      echo "${NOTE} Polkit agent already running. Skipping hyprpolkitagent enable/start." | log PIPE
    fi
  fi
fi

chassis_type=$(detect_waybar_config)
if [ "$chassis_type" = "desktop" ]; then
  config_file="$waybar_config"
else
  config_file="$waybar_config_laptop"
fi

# Point a waybar symlink at a default, relative to .config/waybar -- but only
# when it is missing or broken. A working link is a layout/style chosen with
# WaybarLayout.sh / WaybarStyles.sh and must survive a reinstall.
link_waybar_default() {
  local link="$1" target="$2"
  local waybar_dir="$HOME/.dotfiles/.config/waybar"
  if [ ! -e "$waybar_dir/$target" ]; then
    echo "${WARN} Waybar default $target not found; leaving $link as-is." 2>&1 | log PIPE
  elif [ -e "$waybar_dir/$link" ]; then
    echo "${NOTE} Waybar $link already set; keeping it." 2>&1 | log PIPE
  else
    ln -sfn "$target" "$waybar_dir/$link" 2>&1 | log PIPE
  fi
}

link_waybar_default config "$config_file"

printf "\n%.0s" {1..1}

# SDDM (simple_sddm_2): sddm-sync keeps its wallpaper and colours in step with caelestia
sddm_simple_sddm_2="/usr/share/sddm/themes/simple_sddm_2"
if [ -d "$sddm_simple_sddm_2" ]; then
  systemctl --user enable --now sddm-sync.path sddm-sync.service 2>&1 | log PIPE || \
    echo "${WARN} Could not enable sddm-sync; run: systemctl --user enable --now sddm-sync.path sddm-sync.service" 2>&1 | log PIPE
fi

# additional wallpapers
printf "\n%.0s" {1..1}
echo "${MAGENTA}By default only a few wallpapers are copied${RESET}..."

if confirm "Would you like to download additional wallpapers? ${WARN} This is 1.2GB in size" n; then
  echo "${NOTE} Downloading additional wallpapers..."
  wallpaper_repo=$(mktemp -d)
  if git clone --depth=1 "https://github.com/mylinuxforwork/wallpaper.git" "$wallpaper_repo"; then
    echo "${OK} Wallpapers downloaded successfully." 2>&1 | log PIPE
    mkdir -p "$PICTURES_DIR/wallpapers"
    # Images sit at the repo root beside README and LICENSE
    if find "$wallpaper_repo" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\|gif\)' \
      -exec cp -t "$PICTURES_DIR/wallpapers/" {} +; then
      echo "${OK} Wallpapers copied successfully." 2>&1 | log PIPE
    else
      echo "${ERROR} Copying wallpapers failed" 2>&1 | log PIPE
    fi
    rm -rf "$wallpaper_repo"
  else
    rm -rf "$wallpaper_repo"
    echo "${ERROR} Downloading additional wallpapers failed" 2>&1 | log PIPE
  fi
else
  echo "${NOTE} You chose not to download additional wallpapers." 2>&1 | log PIPE
fi

link_waybar_default style.css "$waybar_style"

printf "\n%.0s" {1..2}
printf "${OK} GREAT! dots is configured"
printf "\n%.0s" {1..1}
printf "${INFO} However, it is ${MAGENTA}HIGHLY SUGGESTED${RESET} to logout and re-login or better reboot to avoid any issues"
printf "\n%.0s" {1..3}
