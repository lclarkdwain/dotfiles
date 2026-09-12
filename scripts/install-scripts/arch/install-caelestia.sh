#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

SNAPSHOT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-migration"

if ! command -v paru >/dev/null 2>&1; then
  log ERROR "paru is required to build the AUR packages"
  exit 1
fi

# The whole rollback plan depends on knowing what was installed first.
if [ -f "$SNAPSHOT_DIR/pkgs-explicit.txt" ]; then
  log WARN "Snapshot already exists in $SNAPSHOT_DIR; keeping the original"
else
  log INFO "Snapshotting package state to $SNAPSHOT_DIR..."
  mkdir -p "$SNAPSHOT_DIR"
  pacman -Qqe > "$SNAPSHOT_DIR/pkgs-explicit.txt"
  pacman -Qq > "$SNAPSHOT_DIR/pkgs-all.txt"
  pacman -Qqm > "$SNAPSHOT_DIR/pkgs-aur.txt"
  pacman -Q quickshell > "$SNAPSHOT_DIR/quickshell-version.txt" 2>/dev/null || true
  date -Is > "$SNAPSHOT_DIR/taken-at.txt"
  log SUCCESS "Snapshot written"
fi

cat <<'NOTE'

  This replaces `quickshell` with `quickshell-git`; they conflict, so the
  stable package is removed. `qs -c overview` runs on the git build afterwards.

  Nothing is uninstalled beyond that. waybar, rofi, swaync and hyprlock all
  stay installed and configured, so the trial is reversible.

NOTE

read -r -p "Continue? [y/N] " reply
case "$reply" in
  [yY]*) ;;
  *) log INFO "Aborted"; exit 0 ;;
esac

log INFO "Installing caelestia-shell and caelestia-cli (builds 6 AUR packages)..."
paru -S --needed caelestia-shell caelestia-cli   # paru may substitute the -git variants

# caelestia's CLI hardcodes these two theme names via dconf but depends on neither; a
# missing GTK theme falls back to stock Adwaita, which is light.
log INFO "Installing the GTK and icon themes caelestia selects..."
sudo pacman -S --needed --noconfirm adw-gtk-theme papirus-icon-theme

if command -v caelestia >/dev/null 2>&1; then
  log SUCCESS "caelestia-cli installed: $(caelestia --version 2>/dev/null || echo present)"
else
  log WARN "caelestia cli not on PATH"
fi

# The running overview keeps the old binary mapped until it is restarted.
log INFO "quickshell is now: $(qs --version 2>&1 | head -1)"
if pgrep -f 'qs -c overview' >/dev/null 2>&1; then
  log WARN "overview is still running on the previous binary; restart it with:"
  log WARN "  pkill -f 'qs -c overview' && hyprctl dispatch 'hl.dsp.exec_raw(\"qs -c overview\")'"
fi

log SUCCESS "Installed. Start it with: caelestia shell -d"
log INFO "Rollback: scripts/install-scripts/arch/uninstall-caelestia.sh"
