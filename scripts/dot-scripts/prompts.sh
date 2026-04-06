#!/usr/bin/env bash
# globals deliberately to minimize side effects.

# Detect keyboard layout via localectl or setxkbmap.
prompt_detect_layout() {
  if command -v localectl >/dev/null 2>&1; then
    local layout
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    [ -n "$layout" ] && {
      echo "$layout"
      return
    }
  fi
  if command -v setxkbmap >/dev/null 2>&1; then
    local layout
    layout=$(setxkbmap -query | awk '/layout/ {print $2}')
    [ -n "$layout" ] && {
      echo "$layout"
      return
    }
  fi
  echo "(unset)"
}

# Confirm or set keyboard layout; writes to SystemSettings.conf.
prompt_keyboard_layout() {
  local layout="$1"

  if [ "$layout" = "(unset)" ]; then
    while true; do
      printf "\n%.0s" {1..1}
      print_color $WARNING "\n    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            STOP AND READ
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected
You need to set it Manually

    !!! WARNING !!!

Setting a wrong Keyboard Layout will cause Hyprland to crash
If you are not sure, just type ${YELLOW}us${RESET}
${SKYBLUE}You can change later in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTE:${RESET}
•  You can also set more than 2 keyboard layouts
•  For example: ${YELLOW}us, kr, gb, ru${RESET}
"
      printf "\n%.0s" {1..1}

      echo -n "${CAT} - Please enter the correct keyboard layout: "
      read new_layout

      if [ -n "$new_layout" ]; then
        layout="$new_layout"
        break
      else
        echo "${CAT} Please enter a keyboard layout."
      fi
    done
  fi

  printf "${NOTE} Detecting keyboard layout to prepare proper Hyprland Settings\n"
  while true; do
    printf "${INFO} Current keyboard layout is ${MAGENTA}$layout${RESET}\n"
    echo -n "${CAT} Is this correct? [y/n] "
    read keyboard_layout
    case $keyboard_layout in
    [yY])
      awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout = " layout} 1' .config/hypr/configs/SystemSettings.conf >temp.conf
      mv temp.conf .config/hypr/configs/SystemSettings.conf
      echo "${NOTE} kb_layout ${MAGENTA}$layout${RESET} configured in settings." 2>&1 | log PIPE
      break
      ;;
    [nN])
      printf "\n%.0s" {1..2}
      print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            STOP AND READ
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected
You need to set it Manually

    !!! WARNING !!!

Setting a wrong Keyboard Layout will cause Hyprland to crash
If you are not sure, just type ${YELLOW}us${RESET}
${SKYBLUE}You can change later in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTE:${RESET}
•  You can also set more than 2 keyboard layouts
•  For example: ${YELLOW}us, kr, gb, ru${RESET}
"
      printf "\n%.0s" {1..1}
      echo -n "${CAT} - Please enter the correct keyboard layout: "
      read new_layout
      awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout = " new_layout} 1' .config/hypr/configs/SystemSettings.conf >temp.conf
      mv temp.conf .config/hypr/configs/SystemSettings.conf
      echo "${OK} kb_layout $new_layout configured in settings." 2>&1 | log PIPE
      break
      ;;
    *)
      echo "${ERROR} Please enter either 'y' or 'n'."
      ;;
    esac
  done
}

# Prompt for resolution choice; echoes "< 1440p" or "≥ 1440p".
prompt_resolution_choice() {
  local choice
  while true; do
    echo "${INFO:-[INFO]} Select monitor resolution for scaling:"
    echo "  1) < 1440p   (lower DPI; smaller displays)"
    echo "  2) ≥ 1440p   (default; 1440p/2k/4k)"

    if ! read -r -p "${CAT} Enter the number of your choice (1 or 2): " choice </dev/tty; then
      echo "${ERROR} Unable to read input (tty unavailable)."
      continue
    fi
    echo "${INFO:-[INFO]} You entered: '$choice'"
    case "$choice" in
    1)
      echo "< 1440p"
      return
      ;;
    2)
      echo "≥ 1440p"
      return
      ;;
    *) echo "${ERROR} Invalid choice. Please enter 1 for < 1440p or 2 for ≥ 1440p." ;;
    esac
  done
}

# Prompt for 12H clock; sets waybar/hyprlock/SDDM changes when accepted.
prompt_clock_12h() {
  local log="$1"
  while true; do
    echo -e "${NOTE} ${SKY_BLUE} By default, KooL's Dots are configured in 24H clock format."
    echo -n "$CAT Do you want to change to 12H (AM/PM) clock format? (y/n): "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [[ "$answer" == "y" ]]; then
      # waybar clocks
      sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
      sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE

      # hyprlock
      local HYPRLOCK_FILE="config/hypr/hyprlock.conf"
      if [ ! -f "$HYPRLOCK_FILE" ] && [ -f "config/hypr/hyprlock-1080p.conf" ]; then
        HYPRLOCK_FILE="config/hypr/hyprlock-1080p.conf"
      fi
      if [ -f "$HYPRLOCK_FILE" ]; then
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
      else
        echo "${WARN} hyprlock template not found; skipping 12H lock format edits" 2>&1 | log PIPE
      fi

      if [ "${EXPRESS_MODE:-0}" -eq 0 ]; then
        apply_sddm_12h_format "/usr/share/sddm/themes/simple-sddm"
        apply_sddm_12h_format "/usr/share/sddm/themes/simple_sddm_2"
        apply_sddm_12h_format_sequoia "/usr/share/sddm/themes/sequoia_2"
      else
        echo "${NOTE:-[NOTE]} Express mode: skipping SDDM 12H edits to avoid sudo prompts." 2>&1 | log PIPE
      fi
      echo "${OK} 12H format set on waybar clocks succesfully." 2>&1 | log PIPE
      return
    elif [[ "$answer" == "n" ]]; then
      echo "${NOTE} You chose not to change to 12H format." 2>&1 | log PIPE
      return
    else
      echo "${ERROR} Invalid choice. Please enter y for yes or n for no."
    fi
  done
}

apply_sddm_12h_format() {
  local sddm_directory="$1"

  if [ -d "$sddm_directory" ]; then
    echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 12H format" 2>&1 | log PIPE
    if ! sudo -n sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE; then
      echo "${WARN:-[WARN]} Skipping SDDM 12H edit (sudo password required)." 2>&1 | log PIPE
      return
    fi
    sudo -n sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE || true
  fi
}

apply_sddm_12h_format_sequoia() {
  local sddm_directory="$1"

  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 12H format" 2>&1 | log PIPE
    if ! sudo -n sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE; then
      echo "${WARN:-[WARN]} Skipping sequoia SDDM 12H edit (sudo password required)." 2>&1 | log PIPE
      return
    fi
    if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory/theme.conf"; then
      sudo -n sed -i '/^clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory/theme.conf" 2>&1 | log PIPE || true
    fi
    echo "${OK} 12H format set to SDDM successfully." 2>&1 | log PIPE
  fi
}

# Rainbow borders toggle; returns "disabled" or "kept".
prompt_rainbow_borders() {
  local log="$1"
  echo "${NOTE} ${SKY_BLUE}By default, Rainbow Borders animation is enabled"
  echo "${WARN} However, this uses a bit more CPU and Memory resources."
  if ! read -r -p "${CAT} Do you want to disable Rainbow Borders animation? (y/N): " border_choice </dev/tty; then
    echo "${ERROR} Unable to read input for rainbow borders; leaving as-is." 2>&1 | log PIPE
    echo "kept"
    return
  fi
  if [[ "$border_choice" =~ ^[Yy]$ ]]; then
    mv config/hypr/UserScripts/RainbowBorders.sh config/hypr/UserScripts/RainbowBorders.bak.sh
    sed -i '/exec-once = \$UserScripts\/RainbowBorders.sh/s/^/#/' config/hypr/configs/Startup_Apps.conf
    sed -i '/^[[:space:]]*animation = borderangle, 1, 180, liner, loop/s/^/#/' config/hypr/configs/UserAnimations.conf
    echo "${OK} Rainbow borders are now disabled." 2>&1 | log PIPE
    echo "disabled"
  else
    echo "${NOTE} No changes made. Rainbow borders remain enabled." 2>&1 | log PIPE
    echo "kept"
  fi
}
