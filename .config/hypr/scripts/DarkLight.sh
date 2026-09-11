#!/usr/bin/env bash
# LOCAL DEVIATION: rewritten dark/light toggle; mode lives in ~/.cache/.theme_mode

SCRIPTSDIR="$HOME/.config/hypr/scripts"
mode_file="$HOME/.cache/.theme_mode"
notif="$HOME/.config/swaync/images/bell.png"

# One toggle at a time
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/darklight.lock"
flock -n 9 || exit 0

if [[ "$(cat "$mode_file" 2>/dev/null)" == "Light" ]]; then
    next_mode="Dark"
else
    next_mode="Light"
fi
notify-send -u low -i "$notif" " Switching to" " $next_mode mode"

# Installed Dark/Light twin of a theme name
twin() {
    local current="$1" subdir="$2" candidate dir
    case "$current" in
        *-Dark*) candidate="${current/-Dark/-$next_mode}" ;;
        *-Light*) candidate="${current/-Light/-$next_mode}" ;;
        *) return 1 ;;
    esac
    for dir in "$HOME/.$subdir" "$HOME/.local/share/$subdir" "/usr/share/$subdir"; do
        [[ -d "$dir/$candidate" ]] && { printf '%s\n' "$dir/$candidate"; return 0; }
    done
    return 1
}

# GTK
iface="org.gnome.desktop.interface"
if [[ "$next_mode" == "Dark" ]]; then
    gsettings set "$iface" color-scheme 'prefer-dark'
    prefer_dark=1
else
    gsettings set "$iface" color-scheme 'prefer-light'
    prefer_dark=0
fi

gtk_theme=""
if theme_dir="$(twin "$(gsettings get "$iface" gtk-theme | tr -d "'")" themes)"; then
    gtk_theme="$(basename "$theme_dir")"
    gsettings set "$iface" gtk-theme "$gtk_theme"
    # GTK4 apps read ~/.config/gtk-4.0, not gtk-theme
    if [[ -d "$theme_dir/gtk-4.0" ]]; then
        mkdir -p "$HOME/.config/gtk-4.0"
        for f in gtk.css gtk-dark.css assets; do
            [[ -e "$theme_dir/gtk-4.0/$f" ]] && ln -sfn "$theme_dir/gtk-4.0/$f" "$HOME/.config/gtk-4.0/$f"
        done
    fi
fi

icon_theme=""
if icon_dir="$(twin "$(gsettings get "$iface" icon-theme | tr -d "'")" icons)"; then
    icon_theme="$(basename "$icon_dir")"
    gsettings set "$iface" icon-theme "$icon_theme"
fi

# Keep nwg-look's settings.ini in agreement
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [[ -f "$ini" ]] || continue
    sed -i "s|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=$prefer_dark|" "$ini"
    [[ -n "$gtk_theme" ]] && sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$gtk_theme|" "$ini"
    [[ -n "$icon_theme" ]] && sed -i "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$icon_theme|" "$ini"
done

# Qt; a literal $HOME keeps the tracked configs portable
if [[ "$next_mode" == "Dark" ]]; then
    qt_colors="Catppuccin-Mocha"
    kvantum_theme="catppuccin-mocha-blue"
else
    qt_colors="Catppuccin-Latte"
    kvantum_theme="catppuccin-latte-blue"
fi
for qt in qt5ct qt6ct; do
    conf="$HOME/.config/$qt/$qt.conf"
    [[ -f "$conf" ]] || continue
    sed -i "s|^color_scheme_path=.*|color_scheme_path=\$HOME/.config/$qt/colors/$qt_colors.conf|" "$conf"
    [[ -n "$icon_theme" ]] && sed -i "s|^icon_theme=.*|icon_theme=$icon_theme|" "$conf"
done
kvconfig="$HOME/.config/Kvantum/kvantum.kvconfig"
[[ -f "$kvconfig" ]] && sed -i "s|^theme=.*|theme=$kvantum_theme|" "$kvconfig"

# Regenerate colors with the new palette and reload the bar and menus
echo "$next_mode" >"$mode_file"
"$SCRIPTSDIR/WallustSwww.sh"
"$SCRIPTSDIR/Refresh.sh"

notify-send -u low -i "$notif" " Themes switched to:" " $next_mode Mode"
