#!/usr/bin/env bash
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images"

# LOCAL FIX for Hyprland Lua configs: "hyprctl keyword" is rejected outright
# ("keyword can't work with non-legacy parsers. Use eval."), so blur changes
# silently did nothing. "hyprctl eval" with hl.config() is the supported path.
# "hyprctl getoption" still works, so the read below is unchanged.
set_blur() {
	hyprctl eval "hl.config({ decoration = { blur = { size = $1, passes = $2 } } })" >/dev/null
}

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

# LOCAL FIX: the restore branch used to set a hardcoded 5 2, which silently
# drifted from decoration.blur in UserConfigs/user_decorations.lua (6 3) --
# "Normal Blur" never returned you to your configured values, and pressing the
# bind once left blur permanently reduced. A config reload IS the restore, the
# same approach HyprPerfMode.sh uses. passes == 1 is the reduced state, since
# set_blur below is the only thing that produces it.
if [ "${STATE}" == "1" ]; then
	hyprctl reload >/dev/null
	notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
else
	set_blur 2 1
	notify-send -e -u low -i "$notif/ja.png" " Less Blur"
fi
