#!/bin/bash
# Remove what install-caelestia.sh built: the plugin files from its install manifest,
# the build tree and the swaync mask. The shell clone, caelestia state and packages stay.

set -e

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

  .config/hypr is caelestia-dots' Hyprland config and starts the shell at login, so
  the next session has no bar, launcher or lock screen. The previous configs are
  kept in archive/pre-caelestia; move them back into .config in git before
  logging out.

NOTE

log SUCCESS "caelestia plugin removed"
