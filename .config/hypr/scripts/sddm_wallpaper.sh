#!/usr/bin/env bash
# LOCAL DEVIATION: SDDM wallpaper/colors (--normal|--effects|--sync <image>); no sudo if user-owned

iDIR="$HOME/.config/swaync/images"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_modified="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
rofi_wallust="$HOME/.config/rofi/wallust/colors-rofi.rasi"

# Resolve SDDM themes directory (standard paths and NixOS path)
sddm_themes_dir="/usr/share/sddm/themes"
if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
fi
sddm_simple="$sddm_themes_dir/simple_sddm_2"
sddm_theme_conf="$sddm_simple/theme.conf"

mode="effects"
case "$1" in
    --normal) mode="normal" ;;
    --effects) mode="effects" ;;
    --sync) mode="sync" ;;
esac

# Silent when run as a hook
fail() {
    [[ "$mode" != "sync" ]] && notify-send -i "$iDIR/error.png" "SDDM" "$1"
    exit "${2:-1}"
}

case "$mode" in
    normal) wallpaper_path="$wallpaper_current" ;;
    effects) wallpaper_path="$wallpaper_modified" ;;
    sync) wallpaper_path="$2" ;;
esac
[[ -f "$wallpaper_path" ]] || fail "Wallpaper not found: $wallpaper_path"

# Abort if SDDM is not running (avoid errors on non-SDDM systems)
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet sddm || fail "SDDM is not running. Skipping SDDM wallpaper update." 0
elif ! pidof sddm >/dev/null 2>&1; then
    fail "SDDM is not running. Skipping SDDM wallpaper update." 0
fi
[[ -f "$sddm_theme_conf" ]] || fail "simple_sddm_2 theme not found in $sddm_themes_dir"

# Abort on NixOS where this repo doesn't manage SDDM and themes are typically read-only
if hostnamectl 2>/dev/null | grep -q 'Operating System: NixOS'; then
    fail "NixOS detected: skipping SDDM background change." 0
fi

[[ -f "$rofi_wallust" ]] || fail "Wallust colors file not found ($rofi_wallust). Run Wallust first."

extract_color() {
    grep -oP "$1:\s*\K#[A-Fa-f0-9]+" "$rofi_wallust" | head -n1
}

color1=$(extract_color "color0")
color7=$(extract_color "color14")
color10=$(extract_color "color10")
color12=$(extract_color "color12")
color13=$(extract_color "color13")

missing_colors=()
for var in color1 color7 color10 color12 color13; do
    [[ -z "${!var}" ]] && missing_colors+=("$var")
done
[[ ${#missing_colors[@]} -eq 0 ]] || fail "Missing color(s): ${missing_colors[*]}. Run Wallust first."

# theme.conf key -> color
declare -A theme_colors=(
    [HeaderTextColor]="$color13"
    [DateTextColor]="$color13"
    [TimeTextColor]="$color13"
    [DropdownSelectedBackgroundColor]="$color13"
    [SystemButtonsIconsColor]="$color13"
    [SessionButtonTextColor]="$color13"
    [VirtualKeyboardButtonTextColor]="$color13"
    [HighlightBackgroundColor]="$color12"
    [LoginFieldTextColor]="$color12"
    [PasswordFieldTextColor]="$color12"
    [DropdownBackgroundColor]="$color1"
    [HighlightTextColor]="$color10"
    [PlaceholderTextColor]="$color7"
    [UserIconColor]="$color7"
    [PasswordIconColor]="$color7"
)
sed_args=()
for key in "${!theme_colors[@]}"; do
    sed_args+=(-e "s/^$key=\"#.*\"/$key=\"${theme_colors[$key]}\"/")
done

# Pass "sudo" to run under sudo
apply_theme() {
    local sudo=("$@")
    "${sudo[@]}" sed -i "${sed_args[@]}" "$sddm_theme_conf" || return 1
    # simple_sddm_2 reads Backgrounds/default; update .jpg/.png too if present
    local target
    for target in "$sddm_simple/Backgrounds/default" "$sddm_simple/Backgrounds/default.jpg" "$sddm_simple/Backgrounds/default.png"; do
        [[ "$target" == "$sddm_simple/Backgrounds/default" || -e "$target" ]] || continue
        cmp -s "$wallpaper_path" "$target" || "${sudo[@]}" cp -f "$wallpaper_path" "$target" || return 1
    done
}

if [[ -w "$sddm_theme_conf" && -w "$sddm_simple/Backgrounds" ]]; then
    apply_theme || fail "Could not write to $sddm_simple"
    [[ "$mode" != "sync" ]] && notify-send -i "$iDIR/ja.png" "SDDM" "Background SET"
    exit 0
fi

[[ "$mode" == "sync" ]] && exit 0

# Root-owned theme: ask for the password in a terminal
script="$(declare -p sed_args sddm_simple sddm_theme_conf wallpaper_path iDIR)
$(declare -f apply_theme)
echo 'Enter your password to update SDDM wallpapers and colors'
apply_theme sudo && notify-send -i \"\$iDIR/ja.png\" SDDM 'Background SET'"
wezterm start -- bash -c "$script"
