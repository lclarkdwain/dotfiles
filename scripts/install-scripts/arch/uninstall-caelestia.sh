#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

SNAPSHOT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-migration"

log INFO "Stopping caelestia if it is running..."
pkill -f 'qs -c caelestia' 2>/dev/null || true
caelestia shell -k 2>/dev/null || true

# Resolved dynamically: paru may install either the tagged or the -git variant.
CAELESTIA_PKGS=$(pacman -Qq 2>/dev/null | grep '^caelestia-' | tr '\n' ' ')
if [ -n "$CAELESTIA_PKGS" ]; then
  log INFO "Removing: $CAELESTIA_PKGS"
  # shellcheck disable=SC2086
  paru -Rns --noconfirm $CAELESTIA_PKGS || log WARN "Removal reported errors"
else
  log INFO "No caelestia packages installed"
fi

# quickshell-git conflicts with quickshell, so pacman swaps them back on install.
log INFO "Restoring stable quickshell..."
if pacman -Qq quickshell-git >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm quickshell
  log SUCCESS "quickshell restored: $(pacman -Q quickshell | awk '{print $2}')"
else
  log INFO "quickshell-git not installed; nothing to swap"
fi

# Deliberately not cascade-removed: fuzzel, gpu-screen-recorder and the fonts may be
# wanted on their own, and a rollback should never delete more than it has to.
log INFO "Packages now orphaned (review before removing):"
pacman -Qtdq 2>/dev/null | sed 's/^/  /' || true
echo
log INFO "Remove any you do not want with: sudo pacman -Rns <pkg>"

if [ -f "$SNAPSHOT_DIR/pkgs-explicit.txt" ]; then
  log INFO "Packages added since the pre-caelestia snapshot:"
  comm -13 <(sort "$SNAPSHOT_DIR/pkgs-explicit.txt") <(pacman -Qqe | sort) | sed 's/^/  /'
fi

cat <<'NOTE'

  Config rollback is separate and lives in git:

    git -C ~/.dotfiles diff            # see what changed
    git -C ~/.dotfiles log --oneline   # find the pre-caelestia commit

  Do NOT run `git checkout -- .` unless the work you want to keep is already
  committed; it discards every uncommitted change, sysmon included.

  To bring back the sysmon panel, uncomment its exec_once line in
  .config/hypr/configs/system_startup.lua and its keybind in
  UserConfigs/user_keybinds.lua, then: hyprctl reload

NOTE

log SUCCESS "Rollback complete"
