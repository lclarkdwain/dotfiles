#!/bin/bash
#
# Remove what install-caelestia.sh built, and nothing else.
#
# Removed:
#   - the QML plugin and version helper under ~/.local, read file by file from CMake's
#     install manifest, so nothing else under ~/.local can be touched
#   - the out-of-tree build (~1.7G of precompiled headers)
#   - the swaync mask, so a notification daemon can take the bus again. .config/systemd
#     is stowed, so this deletes the tracked link .config/systemd/user/swaync.service.
#
# Kept, deliberately:
#   - the clone at ~/.config/quickshell/caelestia: it may hold local changes that exist
#     nowhere else (check with `git -C ~/.config/quickshell/caelestia status`)
#   - ~/.local/state/caelestia: scheme, wallpaper and notification history
#   - every package: quickshell-git is also the runtime for the overview, and the fonts
#     and tools may be wanted on their own
#   - the config in this repo that points at caelestia; that rollback lives in git

set -e

# global_fn.sh provides log and sources utilities.sh itself.
if ! source "$(dirname "$(realpath "$0")")/global_fn.sh"; then
  echo "failed to source global_fn.sh"
  exit 1
fi

SHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-plugin-build"
MANIFEST="$BUILD_DIR/install_manifest.txt"
PREFIX="$HOME/.local"

log INFO "Stopping the caelestia shell..."
caelestia shell -k >/dev/null 2>&1 || true
pkill -f 'qs -c caelestia' 2>/dev/null || true

if [ -f "$MANIFEST" ]; then
  log INFO "Removing the $(wc -l < "$MANIFEST") plugin files listed in the install manifest..."
  while IFS= read -r file; do
    case "$file" in
      "$PREFIX/"*) rm -f -- "$file" ;;
      *) log WARN "not removing $file: outside $PREFIX" ;;
    esac
  done < "$MANIFEST"
  for dir in "$PREFIX/lib/qt6/qml/Caelestia" "$PREFIX/lib/caelestia"; do
    if [ -d "$dir" ]; then find "$dir" -depth -type d -empty -delete; fi
  done
  log INFO "Removing the build tree at $BUILD_DIR..."
  rm -rf -- "$BUILD_DIR"
else
  log WARN "No install manifest at $MANIFEST, so the installed files cannot be listed safely."
  log WARN "Remove by hand: $PREFIX/lib/qt6/qml/Caelestia and $PREFIX/lib/caelestia"
fi

log INFO "Unmasking swaync.service..."
systemctl --user unmask swaync.service >/dev/null 2>&1 || \
  log WARN "could not unmask swaync.service; run: systemctl --user unmask swaync"

cat <<NOTE

  Kept:
    $SHELL_DIR
        the source clone, including any local changes
    ${XDG_STATE_HOME:-$HOME/.local/state}/caelestia
        scheme, wallpaper and notification history
    packages
        remove the CLI with: paru -Rns caelestia-cli
        leave quickshell-git: the overview runs on it

  The config in this repo still starts caelestia at login (system_startup.lua),
  dispatches caelestia:* from the keybinds, and reads its colour files in hyprlock
  and rofi. Revert those in git before logging out, or the next session has no bar.

NOTE

log SUCCESS "caelestia plugin removed"
