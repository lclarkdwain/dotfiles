#!/usr/bin/env bash
# LOCAL DEVIATION: personal settings menu, replaces Kool_Quick_Settings.sh

hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
scripts="$hypr_dir/scripts"
user_scripts="$hypr_dir/UserScripts"
configs="$hypr_dir/configs"
user_configs="$hypr_dir/UserConfigs"
rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-edit.rasi"
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images"

# Terminal and editor come from UserConfigs/user_defaults.lua
defaults_value() {
    sed -n "s/^[[:space:]]*KOOLDOTS_DEFAULTS\.$1[[:space:]]*=[[:space:]]*\"\(.*\)\"[[:space:]]*$/\1/p" \
        "$user_configs/user_defaults.lua" 2>/dev/null | tail -n1
}
term="$(defaults_value term)"
edit="$(defaults_value visual)"
[[ -n "$edit" ]] || edit="$(defaults_value edit)"
term="${term:-wezterm}"
edit="${edit:-${EDITOR:-nano}}"

# entry ICON LABEL "run|run_on_monitor|app|file TARGET", shown in this order
labels=()
actions=()
entry() {
    labels+=("$1  $2")
    actions+=("$3")
}
entry $'\U000F030C' "Keybind cheat sheet" "run $scripts/KeyHints.sh"
entry $'\U000F0349' "Search keybinds" "run $scripts/KeyBinds.sh"

entry $'\U000F0E09' "Wallpaper" "run $user_scripts/WallpaperSelect.sh"
entry $'\U000F050E' "Toggle dark / light mode" "run $scripts/DarkLight.sh"
entry $'\U000F03D8' "Waybar style" "run $scripts/WaybarStyles.sh"
entry $'\U000F056E' "Waybar layout" "run $scripts/WaybarLayout.sh"
entry $'\U000F0279' "Rofi theme" "run $scripts/RofiThemeSelector.sh"
entry $'\U000F05D8' "Window animations" "run $scripts/Animations.sh"
entry $'\U000F0463' "Starship prompt" "run $scripts/ChangeStarshipPrompt.sh"
entry $'\U000F00E3' "GTK theme (nwg-look)" "app nwg-look"
entry $'\U000F027C' "Qt6 theme (qt6ct)" "app qt6ct"
entry $'\U000F027C' "Qt5 theme (qt5ct)" "app qt5ct"
entry $'\U000F033E' "Lock screen wallpaper" "run_on_monitor $scripts/HyprlockWallpaperSelect.sh"
entry $'\U000F0342' "Login screen wallpaper" "run $scripts/sddm_wallpaper.sh --normal"

entry $'\U000F037A' "Monitors & workspaces" "app nwg-displays"
entry $'\U000F0E51' "Monitor profiles" "run $scripts/MonitorProfiles.sh"
entry $'\U000F04C5' "Performance mode" "run $scripts/HyprPerfMode.sh"
entry $'\U000F0954' "Waybar clock 12h / 24h" "run $scripts/ToggleWaybarTime.sh"
entry $'\U000F050F' "Weather units °C / °F" "run $scripts/Toggle-weather-waybar-units.sh"

entry $'\U000F03EB' "Edit defaults (terminal, editor, …)" "file $user_configs/user_defaults.lua"
entry $'\U000F03EB' "Edit keybinds" "file $user_configs/user_keybinds.lua"
entry $'\U000F03EB' "Edit startup apps" "file $user_configs/user_startup.lua"
entry $'\U000F03EB' "Edit window rules" "file $user_configs/user_window_rules.lua"
entry $'\U000F03EB' "Edit layer rules" "file $user_configs/user_layer_rules.lua"
entry $'\U000F03EB' "Edit settings" "file $user_configs/user_settings.lua"
entry $'\U000F03EB' "Edit decorations" "file $user_configs/user_decorations.lua"
entry $'\U000F03EB' "Edit animations" "file $user_configs/user_animations.lua"
entry $'\U000F03EB' "Edit environment variables" "file $user_configs/user_env.lua"
entry $'\U000F03EB' "Edit laptop settings" "file $user_configs/user_laptops.lua"
entry $'\U000F107B' "Edit system keybinds" "file $configs/system_keybinds.lua"
entry $'\U000F107B' "Edit system startup apps" "file $configs/system_startup.lua"
entry $'\U000F107B' "Edit system window rules" "file $configs/system_window_rules.lua"
entry $'\U000F107B' "Edit system layer rules" "file $configs/system_layer_rules.lua"
entry $'\U000F107B' "Edit system settings" "file $configs/system_settings.lua"

is_tui_editor() {
    case "$(basename "${1%% *}")" in
        vi | vim | nvim | nano | hx | helix | kak | micro | emacs-nox) return 0 ;;
    esac
    return 1
}

pkill -x rofi

# Resolve the monitor before rofi takes focus
monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' | head -n1)"
idx="$(printf '%s\n' "${labels[@]}" | rofi -i -dmenu -format i -config "$rofi_theme" -mesg $'\U000F0493  Settings')"
[[ "$idx" =~ ^[0-9]+$ ]] || exit 0

read -r kind target <<<"${actions[$idx]}"
case "$kind" in
    run) exec $target ;;
    run_on_monitor) exec $target $monitor ;;
    app)
        if ! command -v "$target" >/dev/null 2>&1; then
            notify-send -i "$iDIR/error.png" "Settings" "Install $target first"
            exit 1
        fi
        exec "$target"
        ;;
    file)
        if is_tui_editor "$edit"; then
            exec $term -e $edit "$target"
        else
            exec $edit "$target"
        fi
        ;;
esac
