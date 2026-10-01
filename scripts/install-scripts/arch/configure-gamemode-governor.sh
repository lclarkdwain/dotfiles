#!/bin/bash

# Laptops: stop GameMode switching the CPU governor to "performance" in games, which runs hotter.
# Per machine, so it goes in /etc/gamemode.ini; the tracked ~/.config/gamemode.ini leaves desiredgov unset.
# Undo: sudo rm /etc/gamemode.ini

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

gamemode_conf="/etc/gamemode.ini"
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

if [ -z "$governor" ]; then
  log NOTE "This machine has no CPU frequency governor; skipping."
  exit 0
fi

if [ "$governor" = "performance" ]; then
  log NOTE "The CPU governor is already {GOLD}performance{RESET}; GameMode has nothing to switch. Skipping."
  exit 0
fi

if [ -f "$gamemode_conf" ]; then
  log WARN "$gamemode_conf already exists; leaving it untouched."
else
  sudo tee "$gamemode_conf" >/dev/null <<CONF
[general]
; Keep the governor this machine already uses instead of switching to "performance" in games
desiredgov=$governor
CONF
  log OK "Wrote $gamemode_conf: GameMode keeps the {GREEN}$governor{RESET} governor."
fi

# gamemoded only reads its config at start; it is D-Bus activated, so it comes back on the next game
systemctl --user stop gamemoded.service 2>/dev/null || true
