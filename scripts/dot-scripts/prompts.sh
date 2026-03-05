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
  local choice
  while true; do
    echo "${INFO:-[INFO]} Select clock format:"
    echo "  1) 12H (AM/PM)"
    echo "  2) 24H (default)"
    if ! read -r -p "${CAT} Enter the number of your choice (1 or 2): " choice </dev/tty; then
      echo "${ERROR} Unable to read input (tty unavailable)."
      continue
    fi
    echo "${INFO:-[INFO]} You entered: '$choice'"
    case "$choice" in
    1)
      _apply_waybar_12h
      _apply_hyprlock_12h
      echo "${NOTE:-[NOTE]} SDDM changes require sudo. Please enter your password if prompted."
      sudo -v 2>/dev/null || { echo "${WARN:-[WARN]} Skipping SDDM edits (sudo unavailable)." 2>&1 | log PIPE; }
      if sudo -n true 2>/dev/null; then
        apply_sddm_12h_format "/usr/share/sddm/themes/simple-sddm"
        apply_sddm_12h_format "/usr/share/sddm/themes/simple_sddm_2"
        apply_sddm_12h_format_sequoia "/usr/share/sddm/themes/sequoia_2"
      fi
      echo "${OK} 12H format set successfully." 2>&1 | log PIPE
      return
      ;;
    2)
      _apply_waybar_24h
      _apply_hyprlock_24h
      echo "${NOTE:-[NOTE]} SDDM changes require sudo. Please enter your password if prompted."
      sudo -v 2>/dev/null || { echo "${WARN:-[WARN]} Skipping SDDM edits (sudo unavailable)." 2>&1 | log PIPE; }
      if sudo -n true 2>/dev/null; then
        apply_sddm_24h_format "/usr/share/sddm/themes/simple-sddm"
        apply_sddm_24h_format "/usr/share/sddm/themes/simple_sddm_2"
        apply_sddm_24h_format_sequoia "/usr/share/sddm/themes/sequoia_2"
      fi
      echo "${OK} 24H format set successfully." 2>&1 | log PIPE
      return
      ;;
    *) echo "${ERROR} Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

_apply_waybar_12h() {
  sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
}

_apply_waybar_24h() {
  sed -i 's#^\(\s*\)\("format": " {:%I:%M %p}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": " {:%H:%M:%S}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "  {:%H:%M}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%I:%M %p - %d/%b}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%H:%M - %d/%b}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)\("format": "{:%A, %I:%M %P}",\) #\1//\2#g' .config/waybar/Modules 2>&1 | log PIPE
  sed -i 's#^\(\s*\)//\("format": "{:%a %d | %H:%M}",\) #\1\2#g' .config/waybar/Modules 2>&1 | log PIPE
}

_apply_hyprlock_12h() {
  local HYPRLOCK_FILE=".config/hypr/hyprlock.conf"
  if [ -f "$HYPRLOCK_FILE" ]; then
    sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
  else
    echo "${WARN} hyprlock.conf not found; skipping 12H lock format edits" 2>&1 | log PIPE
  fi
}

_apply_hyprlock_24h() {
  local HYPRLOCK_FILE=".config/hypr/hyprlock.conf"
  if [ -f "$HYPRLOCK_FILE" ]; then
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/\1    text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/\1    text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
    sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/# &/' "$HYPRLOCK_FILE" 2>&1 | log PIPE
  else
    echo "${WARN} hyprlock.conf not found; skipping 24H lock format edits" 2>&1 | log PIPE
  fi
}

apply_sddm_12h_format() {
  local sddm_directory="$1"
  if [ -d "$sddm_directory" ]; then
    echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 12H format" 2>&1 | log PIPE
    sudo -n true 2>/dev/null || {
      echo "${WARN:-[WARN]} Skipping SDDM 12H edit (sudo password required)." 2>&1 | log PIPE
      return
    }
    sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
  fi
}

apply_sddm_12h_format_sequoia() {
  local sddm_directory="$1"
  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 12H format" 2>&1 | log PIPE
    sudo -n true 2>/dev/null || {
      echo "${WARN:-[WARN]} Skipping sequoia SDDM 12H edit (sudo password required)." 2>&1 | log PIPE
      return
    }
    sudo sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory/theme.conf"; then
      sudo sed -i '/^## clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    fi
    echo "${OK} 12H format set to SDDM successfully." 2>&1 | log PIPE
  fi
}

apply_sddm_24h_format() {
  local sddm_directory="$1"
  if [ -d "$sddm_directory" ]; then
    echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 24H format" 2>&1 | log PIPE
    sudo -n true 2>/dev/null || {
      echo "${WARN:-[WARN]} Skipping SDDM 24H edit (sudo password required)." 2>&1 | log PIPE
      return
    }
    sudo sed -i 's|^## HourFormat="HH:mm"|HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    sudo sed -i 's|^HourFormat="hh:mm AP"|## HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
  fi
}

apply_sddm_24h_format_sequoia() {
  local sddm_directory="$1"
  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 24H format" 2>&1 | log PIPE
    sudo -n true 2>/dev/null || {
      echo "${WARN:-[WARN]} Skipping sequoia SDDM 24H edit (sudo password required)." 2>&1 | log PIPE
      return
    }
    sudo sed -i 's|^## clockFormat="HH:mm"|clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    sudo sed -i '/^clockFormat="hh:mm AP"/d' "$sddm_directory/theme.conf" 2>&1 | log PIPE
    echo "${OK} 24H format restored to SDDM successfully." 2>&1 | log PIPE
  fi
}
