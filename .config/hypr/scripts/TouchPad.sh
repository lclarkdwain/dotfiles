#!/usr/bin/env bash
# LOCAL FIX: auto-detect the touchpad and toggle it via hl.device (TOUCHPAD_DEVICE overrides)

notif="$HOME/.config/swaync/images/ja.png"
state_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.disabled"

device="${TOUCHPAD_DEVICE:-}"
if [[ -z "$device" && -s "$state_file" ]]; then
    device="$(<"$state_file")"
fi
if [[ -z "$device" ]]; then
    device="$(hyprctl devices -j | jq -r '[.mice[].name | select(test("touchpad"; "i"))][0] // empty')"
fi
if [[ -z "$device" ]]; then
    notify-send -u low -i "$notif" " Touchpad" " No touchpad found (set TOUCHPAD_DEVICE)"
    exit 1
fi

set_enabled() {
    hyprctl eval "hl.device({ name = \"$device\", enabled = $1 })" >/dev/null
}

if [[ -s "$state_file" ]]; then
    set_enabled true
    rm -f "$state_file"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
else
    set_enabled false
    printf '%s\n' "$device" >"$state_file"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
fi
