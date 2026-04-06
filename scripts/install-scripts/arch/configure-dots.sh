#!/bin/bash

clear
wallpaper=$HOME/.dotfiles/.config/hypr/wallpaper_effects/.wallpaper_current
waybar_style="$HOME/.dotfiles/.config/waybar/style/Extra-Prismatic-Glow.css"
waybar_config="$HOME/.dotfiles/.config/waybar/configs/TOP-Default"
waybar_config_laptop="$HOME/.dotfiles/.config/waybar/configs/TOP-Default-Laptop"

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

detect_nvidia_adjust
detect_vm_adjust

# activating hyprcursor on env by checking if the directory ~/.icons/Bibata-Modern-Ice/hyprcursors exists
if [ -d "$HOME/.icons/Bibata-Modern-Ice/hyprcursors" ]; then
  HYPRCURSOR_ENV_FILE=".config/hypr/configs/ENVariables.conf"
  echo "${INFO} Bibata-Hyprcursor directory detected. Activating Hyprcursor...." 2>&1 | log PIPE || true
  sed -i 's/^#env = HYPRCURSOR_THEME,Bibata-Modern-Ice/env = HYPRCURSOR_THEME,Bibata-Modern-Ice/' "$HYPRCURSOR_ENV_FILE"
  sed -i 's/^#env = HYPRCURSOR_SIZE,24/env = HYPRCURSOR_SIZE,24/' "$HYPRCURSOR_ENV_FILE"
fi

printf "\n%.0s" {1..1}

layout=$(prompt_detect_layout)
prompt_keyboard_layout "$layout"

enable_asusctl
enable_blueman
enable_ags
enable_quickshell
ensure_keybinds_init

printf "\n%.0s" {1..1}

choose_default_editor
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
if [ "$resolution" == "< 1440p" ]; then
  # kitty font size
  sed -i 's/font_size 16.0/font_size 14.0/' .config/kitty/kitty.conf
  # hyprlock matters
  if [ -f .config/hypr/hyprlock-1080p.conf ]; then
    cp .config/hypr/hyprlock-1080p.conf .config/hypr/hyprlock.conf
  fi
  # rofi fonts reduction
  rofi_config_file=".config/rofi/0-shared-fonts.rasi"
  if [ -f "$rofi_config_file" ]; then
    sed -i '/element-text {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 13"/font: "JetBrainsMono Nerd Font SemiBold 11"/' "$rofi_config_file" 2>&1 | log PIPE
    sed -i '/configuration {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 15"/font: "JetBrainsMono Nerd Font SemiBold 13"/' "$rofi_config_file" 2>&1 | log PIPE
  fi
elif [ "$resolution" == "≥ 1440p" ]; then
  # kitty font size (restore default)
  sed -i 's/font_size 14.0/font_size 16.0/' .config/kitty/kitty.conf
  # hyprlock matters
  if [ -f .config/hypr/hyprlock-2k.conf ]; then
    cp .config/hypr/hyprlock-2k.conf .config/hypr/hyprlock.conf
  fi
  # rofi fonts restoration
  rofi_config_file=".config/rofi/0-shared-fonts.rasi"
  if [ -f "$rofi_config_file" ]; then
    sed -i '/element-text {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 11"/font: "JetBrainsMono Nerd Font SemiBold 13"/' "$rofi_config_file" 2>&1 | log PIPE
    sed -i '/configuration {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 13"/font: "JetBrainsMono Nerd Font SemiBold 15"/' "$rofi_config_file" 2>&1 | log PIPE
  fi
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

# Set some files as executable
chmod +x ".config/hypr/scripts/"* 2>&1 | log PIPE
chmod +x ".config/hypr/UserScripts/"* 2>&1 | log PIPE
# Set executable for initial-boot.sh
chmod +x ".config/hypr/initial-boot.sh" 2>&1 | log PIPE

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
  config_remove=" Laptop"
else
  config_file="$waybar_config_laptop"
  config_remove=""
fi

# Check if ~/.config/waybar/config does not exist or is a symlink
# if [ ! -e "$HOME/.dotfiles/.config/waybar/config" ] || [ -L "$HOME/.dotfiles/.config/waybar/config" ]; then
#   ln -sf "$config_file" "$HOME/.dotfiles/.config/waybar/config" 2>&1 | log PIPE
# fi

# Ensure waybar config uses the normalized default.
# - If the current path is not a symlink (regular file), convert it to a symlink.
# - If the symlink points somewhere else (or is broken), reset it to the new default.
WAYBAR_CONFIG_LINK="$HOME/.dotfiles/.config/waybar/config"
WAYBAR_CONFIG_TARGET="$config_file"
if [ -e "$WAYBAR_CONFIG_TARGET" ]; then
  if [ -L "$WAYBAR_CONFIG_LINK" ]; then
    current_target=$(readlink "$WAYBAR_CONFIG_LINK" || true)
    if [ "$current_target" != "$WAYBAR_CONFIG_TARGET" ] || [ ! -e "$WAYBAR_CONFIG_LINK" ]; then
      ln -sf "$WAYBAR_CONFIG_TARGET" "$WAYBAR_CONFIG_LINK" 2>&1 | log PIPE
    fi
  else
    ln -sf "$WAYBAR_CONFIG_TARGET" "$WAYBAR_CONFIG_LINK" 2>&1 | log PIPE
  fi
else
  echo "${WARN} Waybar default config target not found at $WAYBAR_CONFIG_TARGET; leaving $WAYBAR_CONFIG_LINK as-is." 2>&1 | log PIPE
fi

# Remove inappropriate waybar configs
# rm -rf ".config/waybar/configs/[TOP] Default$config_remove" \
#   ".config/waybar/configs/[BOT] Default$config_remove" \
#   ".config/waybar/configs/[TOP] Default$config_remove (old v1)" \
#   ".config/waybar/configs/[TOP] Default$config_remove (old v2)" \
#   ".config/waybar/configs/[TOP] Default$config_remove (old v3)" \
#   ".config/waybar/configs/[TOP] Default$config_remove (old v4)" 2>&1 | log PIPE || true

printf "\n%.0s" {1..1}

# for SDDM (simple_sddm_2)
sddm_simple_sddm_2="/usr/share/sddm/themes/simple_sddm_2"
if [ -d "$sddm_simple_sddm_2" ]; then
  while true; do
    echo -n "${CAT} SDDM simple_sddm_2 theme detected! Apply current wallpaper as SDDM background? (y/n): "
    read SDDM_WALL

    # Remove any leading/trailing whitespace or newlines from input
    SDDM_WALL=$(echo "$SDDM_WALL" | tr -d '\n' | tr -d ' ')

    case $SDDM_WALL in
    [Yy])
      # Copy the wallpaper, ignore errors if the file exists or fails
      sudo -n cp -r ".config/hypr/wallpaper_effects/.wallpaper_current" "/usr/share/sddm/themes/simple_sddm_2/Backgrounds/default" || true
      echo "${NOTE} Current wallpaper applied as default SDDM background" 2>&1 | log PIPE
      break
      ;;
    [Nn])
      echo "${NOTE} You chose not to apply the current wallpaper to SDDM." 2>&1 | log PIPE
      break
      ;;
    *)
      echo "Please enter 'y' or 'n' to proceed."
      ;;
    esac
  done
fi

# additional wallpapers
printf "\n%.0s" {1..1}
echo "${MAGENTA}By default only a few wallpapers are copied${RESET}..."

while true; do
  echo "${NOTE} A number of these wallpapers are AI generated or enhanced. Select (N/n) if this is an issue for you. "
  echo -n "${CAT} Would you like to download additional wallpapers? ${WARN} This is 1GB in size (y/n): "
  read WALL

  case $WALL in
  [Yy])
    echo "${NOTE} Downloading additional wallpapers..."
    if git clone "https://github.com/LinuxBeginnings/Wallpaper-Bank.git"; then
      echo "${OK} Wallpapers downloaded successfully." 2>&1 | log PIPE

      # Check if wallpapers directory exists and create it if not
      if [ ! -d "$PICTURES_DIR/wallpapers" ]; then
        mkdir -p "$PICTURES_DIR/wallpapers"
        echo "${OK} Created wallpapers directory." 2>&1 | log PIPE
      fi

      if cp -R Wallpaper-Bank/wallpapers/* "$PICTURES_DIR/wallpapers/" 2>&1 | log PIPE; then
        echo "${OK} Wallpapers copied successfully." 2>&1 | log PIPE
        rm -rf Wallpaper-Bank 2>&1 # Remove cloned repository after copying wallpapers
        break
      else
        echo "${ERROR} Copying wallpapers failed" 2>&1 | log PIPE
      fi
    else
      echo "${ERROR} Downloading additional wallpapers failed" 2>&1 | log PIPE
    fi
    ;;
  [Nn])
    echo "${NOTE} You chose not to download additional wallpapers." 2>&1 | log PIPE
    break
    ;;
  *)
    echo "Please enter 'y' or 'n' to proceed."
    ;;
  esac
done

# Check if ~/.config/waybar/style.css does not exist or is a symlink
# if [ ! -e "$HOME/.dotfiles/.config/waybar/style.css" ] || [ -L "$HOME/.dotfiles/.config/waybar/style.css" ]; then
#   ln -sf "$waybar_style" "$HOME/.dotfiles/.config/waybar/style.css" 2>&1 | log PIPE
# fi

# Ensure waybar style uses the normalized default.
# - If the current path is not a symlink (regular file), convert it to a symlink.
# - If the symlink points somewhere else (or is broken), reset it to the new default.
WAYBAR_STYLE_LINK="$HOME/.dotfiles/.config/waybar/style.css"
WAYBAR_STYLE_TARGET="$waybar_style"
if [ -e "$WAYBAR_STYLE_TARGET" ]; then
  if [ -L "$WAYBAR_STYLE_LINK" ]; then
    current_target=$(readlink "$WAYBAR_STYLE_LINK" || true)
    if [ "$current_target" != "$WAYBAR_STYLE_TARGET" ] || [ ! -e "$WAYBAR_STYLE_LINK" ]; then
      ln -sf "$WAYBAR_STYLE_TARGET" "$WAYBAR_STYLE_LINK" 2>&1 | log PIPE
    fi
  else
    ln -sf "$WAYBAR_STYLE_TARGET" "$WAYBAR_STYLE_LINK" 2>&1 | log PIPE
  fi
else
  echo "${WARN} Waybar default style target not found at $WAYBAR_STYLE_TARGET; leaving $WAYBAR_STYLE_LINK as-is." 2>&1 | log PIPE
fi

printf "\n%.0s" {1..1}

# initialize wallust to avoid config error on hyprland
wallust run -s $wallpaper 2>&1 | log PIPE

printf "\n%.0s" {1..2}
printf "${OK} GREAT! dots is configured"
printf "\n%.0s" {1..1}
printf "${INFO} However, it is ${MAGENTA}HIGHLY SUGGESTED${RESET} to logout and re-login or better reboot to avoid any issues"
printf "\n%.0s" {1..3}
