#!/usr/bin/env bash
# LOCAL DEVIATION: cheat sheet generated from the loaded binds (SUPER H)

title="Keybind Cheat Sheet"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

# A second press closes it
if pkill -f -- "^yad --title=$title"; then
  exit 0
fi
pkill -x rofi

files=("$hypr_dir/configs/system_keybinds.lua")
for f in "$hypr_dir/configs/system_laptops.lua" "$hypr_dir/UserConfigs/user_keybinds.lua" "$hypr_dir/UserConfigs/user_overrides.lua"; do
  [[ -f "$f" ]] && files+=("$f")
done

"$hypr_dir/scripts/keybinds_parser.py" --cheatsheet "${files[@]}" |
  tr '\t' '\n' |
  GDK_BACKEND=wayland yad \
    --title="$title" \
    --text="Type to filter  ·  Esc to close  ·  SUPER SHIFT E for settings" \
    --list \
    --column=Keys \
    --column=Action \
    --search-column=2 \
    --no-click \
    --no-buttons \
    --width=760 \
    --height=820 \
    --center
