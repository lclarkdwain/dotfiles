#!/usr/bin/env bash
# Toggle window transparency on the fly.
#
# LOCAL FIX: replaces the SUPER CTRL O binding, which dispatched `setprop
# active opaque toggle`. `setprop` is an hyprctl request, not a dispatcher --
# hyprctl answers "unknown request" -- and the Lua helper's exec_raw fallback
# accepts any string without validating it, so the bind failed silently.
#
# Off registers a catch-all rule at full opacity. Runtime rules do apply to
# windows that are already open, so this takes effect immediately. On drops
# that rule via `hyprctl reload`, which rebuilds every window rule from
# configs/system_window_rules.lua -- the same restore path HyprPerfMode.sh uses.

notif="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images/ja.png"
state="${XDG_CACHE_HOME:-$HOME/.cache}/.opacity_mode"

mode="$(cat "$state" 2>/dev/null)"
[[ "$mode" == "off" ]] || mode="on"

if [[ "$mode" == "on" ]]; then
    hyprctl eval "hl.window_rule({ name = 'opacity-toggle', match = { class = '.*' }, opacity = 1.0 })" >/dev/null
    echo "off" >"$state"
    notify-send -e -u low -i "$notif" " Window transparency:" " off"
else
    hyprctl reload >/dev/null
    echo "on" >"$state"
    notify-send -e -u low -i "$notif" " Window transparency:" " on"
fi
