#!/usr/bin/env bash
# App enablement helpers.

enable_asusctl() {
  if command -v asusctl >/dev/null 2>&1; then
    local hypr_user=".config/caelestia/hypr-user.lua"
    local line='hl.on("hyprland.start", function() hl.exec_cmd("rog-control-center") end)'
    grep -qF "$line" "$hypr_user" || printf '\n%s\n' "$line" >>"$hypr_user"
  fi
}
