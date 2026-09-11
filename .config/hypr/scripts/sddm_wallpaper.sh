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

# Named after the wallust palette entry each one holds
c0=$(extract_color "color0")
c10=$(extract_color "color10")
c13=$(extract_color "color13")
c14=$(extract_color "color14")
c15=$(extract_color "color15")

missing_colors=()
for var in c0 c10 c13 c14 c15; do
    [[ -z "${!var}" ]] && missing_colors+=("$var")
done
[[ ${#missing_colors[@]} -eq 0 ]] || fail "Missing color(s): ${missing_colors[*]}. Run Wallust first."

# WCAG relative luminance of a #RRGGBB color
luminance() {
    local hex="${1#\#}"
    awk -v r="$((16#${hex:0:2}))" -v g="$((16#${hex:2:2}))" -v b="$((16#${hex:4:2}))" \
        'function chan(v,  c) { c = v / 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
         BEGIN { printf "%.6f", 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b) }'
}

# Whichever candidate color reads best on background $1
pick_contrast() {
    local bg_lum best="" best_ratio=0 cand ratio
    bg_lum=$(luminance "$1")
    shift
    for cand in "$@"; do
        ratio=$(awk -v a="$bg_lum" -v b="$(luminance "$cand")" \
            'BEGIN { printf "%.4f", (a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05)) }')
        awk -v r="$ratio" -v m="$best_ratio" 'BEGIN { exit !(r > m) }' && { best="$cand"; best_ratio="$ratio"; }
    done
    printf '%s' "$best"
}

# theme.conf key -> color
declare -A theme_colors=(
    [HeaderTextColor]="$c13"
    [DateTextColor]="$c13"
    [TimeTextColor]="$c13"
    [DropdownSelectedBackgroundColor]="$c13"
    [SystemButtonsIconsColor]="$c13"
    [SessionButtonTextColor]="$c13"
    [VirtualKeyboardButtonTextColor]="$c13"
    [LoginButtonBackgroundColor]="$c13"
    [HighlightBackgroundColor]="$c14"
    [HighlightBorderColor]="$c14"
    [DropdownBackgroundColor]="$c0"
    [LoginFieldBackgroundColor]="$c0"
    [PasswordFieldBackgroundColor]="$c0"
    [HighlightTextColor]="$(pick_contrast "$c14" "$c10" "$c15")"
    [FormBackgroundColor]="$c10"
    [BackgroundColor]="$c10"
    [DimBackgroundColor]="$c10"
    [PlaceholderTextColor]="$c14"
    # Small italic text over the blurred wallpaper: favour the more legible accent
    [WarningColor]="$(pick_contrast "$c10" "$c14" "$c15")"
    [UserIconColor]="$c14"
    [PasswordIconColor]="$c14"
    # Hover states lift one step brighter than their resting color
    [HoverSystemButtonsIconsColor]="$c14"
    [HoverSessionButtonTextColor]="$c14"
    [HoverVirtualKeyboardButtonTextColor]="$c14"
    [HoverUserIconColor]="$c15"
    [HoverPasswordIconColor]="$c15"
    [LoginFieldTextColor]="$c15"
    [PasswordFieldTextColor]="$c15"
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
