#!/usr/bin/env bash
# App enablement helpers.
#
# ~/.config/hypr is an untouched upstream caelestia-dots copy, so personal Hyprland
# additions go in .config/caelestia/hypr-user.lua, which it loads last. There is no
# default-editor prompt any more: the Hyprland setting it wrote is gone, and
# $EDITOR comes from zsh/.zshenv.

enable_asusctl() {
  if command -v asusctl >/dev/null 2>&1; then
    local hypr_user=".config/caelestia/hypr-user.lua"
    local line='hl.on("hyprland.start", function() hl.exec_cmd("rog-control-center") end)'
    grep -qF "$line" "$hypr_user" || printf '\n%s\n' "$line" >>"$hypr_user"
  fi
}
