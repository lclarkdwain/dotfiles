#!/usr/bin/env bash
# Re-apply saved Dark/Light mode on startup without toggling.

SCRIPTSDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
"$SCRIPTSDIR/DarkLight.sh" --apply-current --preserve-wallpaper --no-notify
