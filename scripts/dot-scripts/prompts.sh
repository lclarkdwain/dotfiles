#!/usr/bin/env bash
# globals deliberately to minimize side effects.

# Ask a yes/no question on stdin; Enter picks the default ("y" or "n").
confirm() {
  local question="$1" default="$2" hint answer
  [ "$default" = y ] && hint="[Y/n]" || hint="[y/N]"
  while true; do
    read -r -p "${CAT} $question $hint: " answer
    answer=${answer:-$default}
    case "${answer,,}" in
    y | yes) return 0 ;;
    n | no) return 1 ;;
    *) echo "${ERROR} Please answer y or n." ;;
    esac
  done
}

# Detect the keyboard layout: localectl, then setxkbmap, then whatever the
# Hyprland config already uses. Echoes "(unset)" only if all three come up empty.
prompt_detect_layout() {
  local layout=""
  if command -v localectl >/dev/null 2>&1; then
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
  fi
  # localectl prints the literal "(unset)" when no X11 keymap was ever set,
  # which is normal on a Wayland-only install -- not a detected layout.
  if { [ -z "$layout" ] || [ "$layout" = "(unset)" ]; } && command -v setxkbmap >/dev/null 2>&1; then
    layout=$(setxkbmap -query 2>/dev/null | awk '/^layout/ {print $2}')
  fi
  if [ -z "$layout" ] || [ "$layout" = "(unset)" ]; then
    layout=$(sed -n 's/^[[:space:]]*kb_layout = "\(.*\)".*/\1/p' .config/hypr/configs/system_settings.lua | head -n1)
  fi
  echo "${layout:-(unset)}"
}

# Write kb_layout into the Lua settings Hyprland actually loads.
set_kb_layout() {
  local layout="$1"
  sed -i "s/^\([[:space:]]*kb_layout = \)\".*\"/\1\"$layout\"/" .config/hypr/configs/system_settings.lua
}

layout_help() {
  print_color $WARNING "
Setting a wrong keyboard layout will cause Hyprland to crash.
If you are not sure, just type ${YELLOW}us${RESET}
${SKYBLUE}You can change it later in ~/.config/hypr/configs/system_settings.lua${RESET}

${MAGENTA} NOTE:${RESET}
•  You can also set more than 2 keyboard layouts
•  For example: ${YELLOW}us, kr, gb, ru${RESET}
"
}

# Keyboard layout has no safe default, so an empty answer is re-asked. Fails
# only when input runs out, so the caller can leave the config untouched.
read_layout() {
  local new_layout=""
  while [ -z "$new_layout" ]; do
    read -r -p "${CAT} Please enter the keyboard layout: " new_layout || return 1
  done
  echo "$new_layout"
}

# Confirm or set keyboard layout; writes to configs/system_settings.lua.
prompt_keyboard_layout() {
  local layout="$1"

  if [ "$layout" = "(unset)" ]; then
    print_color $WARNING "\nThe keyboard layout could not be detected. You need to set it manually."
    layout_help
    layout=$(read_layout) || {
      echo "${WARN} No keyboard layout entered; leaving kb_layout unchanged." 2>&1 | log PIPE
      return 0
    }
  fi

  if ! confirm "Keyboard layout is ${MAGENTA}$layout${RESET}. Is this correct?" y; then
    layout_help
    layout=$(read_layout) || {
      echo "${WARN} No keyboard layout entered; leaving kb_layout unchanged." 2>&1 | log PIPE
      return 0
    }
  fi

  set_kb_layout "$layout"
  echo "${OK} kb_layout ${MAGENTA}$layout${RESET} configured in settings." 2>&1 | log PIPE
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
  echo -e "${NOTE} ${SKY_BLUE} By default, these dots use the 24H clock format."
  if confirm "Do you want to change to 12H (AM/PM) clock format?" n; then
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
    local HYPRLOCK_FILE=".config/hypr/hyprlock.conf"
    if [ ! -f "$HYPRLOCK_FILE" ] && [ -f ".config/hypr/hyprlock-1080p.conf" ]; then
      HYPRLOCK_FILE=".config/hypr/hyprlock-1080p.conf"
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
  else
    echo "${NOTE} Keeping the 24H clock format." 2>&1 | log PIPE
  fi
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
