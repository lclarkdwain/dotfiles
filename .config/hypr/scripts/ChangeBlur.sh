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

if [ "${STATE}" == "2" ]; then
	set_blur 2 1
 	notify-send -e -u low -i "$notif/note.png" " Less Blur"
else
	set_blur 5 2
  	notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
fi
