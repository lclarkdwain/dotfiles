#!/usr/bin/env bash
# App enablement and editor selection helpers.
#
# Hyprland runs the Lua config (hyprland.lua), so these write Lua, not the old
# hyprlang .conf files. blueman-applet, quickshell (qs -c overview) and
# KeybindsLayoutInit.sh are already started from configs/system_startup.lua.

enable_asusctl() {
  if command -v asusctl >/dev/null 2>&1; then
    local user_startup=".config/hypr/UserConfigs/user_startup.lua"
    grep -qF 'exec_once("rog-control-center")' "$user_startup" ||
      echo 'exec_once("rog-control-center")' >>"$user_startup"
  fi
}

choose_default_editor() {
  local editor_set=0
  update_editor() {
    local editor=$1
    local user_defaults=".config/hypr/UserConfigs/user_defaults.lua"
    sed -i \
      -e "s/^KOOLDOTS_DEFAULTS\.edit = .*/KOOLDOTS_DEFAULTS.edit = \"$editor\"/" \
      -e "s/^KOOLDOTS_DEFAULTS\.visual = .*/KOOLDOTS_DEFAULTS.visual = \"$editor\"/" \
      "$user_defaults"
    echo "${OK:-[OK]} Default editor set to ${MAGENTA:-}$editor${RESET:-}." 2>&1 | log PIPE
  }
  if command -v nvim &>/dev/null; then
    printf "${INFO:-[INFO]} ${MAGENTA:-}neovim${RESET:-} is detected as installed\n"
    if ! read -r -p "${CAT:-[ACTION]} Do you want to make ${MAGENTA:-}neovim${RESET:-} the default editor? (y/N): " EDITOR_CHOICE </dev/tty; then
      :
    elif [[ "$EDITOR_CHOICE" == "y" || "$EDITOR_CHOICE" == "Y" ]]; then
      update_editor "nvim"
      editor_set=1
    fi
  fi
  printf "\n"
  if [[ "$editor_set" -eq 0 ]] && command -v vim &>/dev/null; then
    printf "${INFO:-[INFO]} ${MAGENTA:-}vim${RESET:-} is detected as installed\n"
    if read -r -p "${CAT:-[ACTION]} Do you want to make ${MAGENTA:-}vim${RESET:-} the default editor? (y/N): " EDITOR_CHOICE </dev/tty; then
      if [[ "$EDITOR_CHOICE" == "y" || "$EDITOR_CHOICE" == "Y" ]]; then
        update_editor "vim"
        editor_set=1
      fi
    fi
  fi
}
