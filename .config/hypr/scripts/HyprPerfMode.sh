#!/usr/bin/env bash
# Compositor performance mode: turns all animations and decorations off.
#
# NOTE: unrelated to Feral GameMode (gamemoded), which is also installed and
# handles CPU governor and scheduling for games. This only touches Hyprland's
# own eye candy. Renamed from GameMode.sh so the two are not confused.

notif="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images/ja.png"
SCRIPTSDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
# shellcheck source=/dev/null
. "$SCRIPTSDIR/WallpaperCmd.sh"

# Detect active Hyprland config mode (Lua entrypoint vs legacy .conf includes)
config_home="${XDG_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
hypr_dir="$config_home/hypr"
lua_entry="$hypr_dir/hyprland.lua"
legacy_lua_entry="$config_home/hyprland.lua"

if [[ -f "$lua_entry" || -f "$legacy_lua_entry" ]]; then
    hypr_config_mode="lua"
else
    hypr_config_mode="conf"
fi

# Check if animations are currently enabled
HYPRGAMEMODE=$(hyprctl getoption animations:enabled -j | jq -r '.bool' 2>/dev/null)
if [[ "$HYPRGAMEMODE" == "null" || -z "$HYPRGAMEMODE" ]]; then
    HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
fi

if [ "$HYPRGAMEMODE" = "true" ] || [ "$HYPRGAMEMODE" = "1" ] ; then
    # ENABLE perf mode (disable animations/decorations)
    if [[ "$hypr_config_mode" == "lua" ]]; then
        hyprctl eval "hl.config({
            animations = { enabled = false },
            decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
            general = { gaps_in = 0, gaps_out = 0, border_size = 1 }
        })"
        hyprctl eval "hl.window_rule({ name = 'gamemode-opacity', match = { class = '.*' }, opacity = 1.0 })"
    else
        hyprctl --batch "\
            keyword animations:enabled 0;\
            keyword decoration:shadow:enabled 0;\
            keyword decoration:blur:enabled 0;\
            keyword general:gaps_in 0;\
            keyword general:gaps_out 0;\
            keyword general:border_size 1;\
            keyword decoration:rounding 0"
        hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    fi

    "$WWW_CMD" kill
    notify-send -e -u low -i "$notif" " Compositor perf mode:" " enabled"
    sleep 0.1
    exit
else
    # DISABLE perf mode: restore animations and decorations.
    #
    # LOCAL FIX: a config reload IS the restore. This previously re-applied
    # hardcoded values (rounding 10, gaps 2/4, border_size 2) that silently
    # drifted from UserConfigs/user_decorations.lua the moment those were
    # edited -- toggling twice would quietly reset the theme to whatever had
    # been frozen into this script. It also had no way to remove the opacity
    # window rule the enable path adds, only to nullify it with a dummy
    # 'NONE' match that stayed registered.
    #
    # `hyprctl reload` re-reads the real config and rebuilds settings and window
    # rules from it, so it restores exactly what is configured, needs no
    # per-config-mode branch, and cannot drift. Verified: values overridden at
    # runtime via `hyprctl eval` return to their configured values on reload.
    hyprctl reload

    # Restore wallpaper using the official daemon script
    if [[ -x "${SCRIPTSDIR}/WallpaperDaemon.sh" ]]; then
        "${SCRIPTSDIR}/WallpaperDaemon.sh" &
    fi

    sleep 0.1
    ${SCRIPTSDIR}/WallustSwww.sh
    sleep 0.5

    # Refresh UI components
    if [[ -x "${SCRIPTSDIR}/Refresh.sh" ]]; then
        "${SCRIPTSDIR}/Refresh.sh"
    else
        hyprctl reload
    fi

    notify-send -e -u normal -i "$notif" " Compositor perf mode:" " disabled"
    exit
fi
