#!/usr/bin/env bash
# Scripts for refreshing ags, waybar, rofi, swaync, wallust

# LOCAL FIX: caelestia is the bar and owns the notification bus. The upstream body
# below restarts waybar on top of it and relaunches swaync with a plain `swaync &`,
# which masking swaync.service cannot stop. Eight scripts still call this file
# (ThemeChanger on SUPER+T, HyprPerfMode on SUPER+SHIFT+G, and the wallpaper and
# waybar menus), so it hands off to the variant that restarts neither instead of every
# caller being repointed. Delete these lines to restore the upstream behaviour.
exec "$(dirname "$(realpath "$0")")/RefreshNoWaybar.sh" "$@"

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
  if [ -e "$1" ]; then
    return 0 # File exists
  else
    return 1 # File does not exist
  fi
}

# Kill already running processes (exclude waybar to avoid double reloads)
_ps=(rofi swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

# Clean up any Waybar-spawned cava instances (unique temp conf names)
pkill -f 'waybar-cava\..*\.conf' 2>/dev/null || true



# some process to kill (exclude waybar to avoid restart loops)
for pid in $(pidof rofi swaync ags swaybg); do
  kill -SIGUSR1 "$pid"
  sleep 0.1
done

# Reload or start waybar once
if pidof waybar >/dev/null; then
  if command -v waybar-msg >/dev/null 2>&1; then
    waybar-msg cmd reload >/dev/null 2>&1 || true
  else
    killall -SIGUSR2 waybar 2>/dev/null || true
  fi
else
  waybar &
fi

# relaunch swaync
sleep 0.3
swaync >/dev/null 2>&1 &
# reload swaync
swaync-client --reload-config

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
