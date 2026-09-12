#!/bin/bash
#
# Caelestia desktop shell: upstream source, installed for local modification.
#
# Everything below this line belongs to caelestia and nothing else in these
# dotfiles depends on it. Remove this script and its packages and the rest of the
# desktop still comes up.
#
# The shell is a git clone at ~/.config/quickshell/caelestia, not a vendored copy.
# Quickshell reads its QML straight from there, so edits are live and hot-reloaded,
# and `git -C ~/.config/quickshell/caelestia diff` always shows exactly what we
# changed against upstream. This repo gitignores that path; it is never tracked here.
#
# The C++ QML plugin has to be compiled. It installs to ~/.local (no sudo);
# UserConfigs/user_env.lua puts ~/.local/lib/qt6/qml on Qt's import path.

set -e

# global_fn.sh provides install_packages and sources utilities.sh (log) itself.
# Sourcing only utilities.sh leaves install_packages undefined, and install-arch.sh
# runs each script through `env` in a fresh process, so nothing is inherited.
if ! source "$(dirname "$(realpath "$0")")/global_fn.sh"; then
  echo "failed to source global_fn.sh"
  exit 1
fi

SHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
SHELL_REPO="https://github.com/caelestia-dots/shell.git"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-plugin-build"
PREFIX="$HOME/.local"

# ---------------------------------------------------------------------------
# Dependencies -- caelestia's, per its README. Not shared with anything else here.
# ---------------------------------------------------------------------------

# quickshell-git specifically: upstream requires the git build, not the tagged one.
runtime_pkgs=(
  quickshell-git
  qt6-base qt6-declarative qt6-imageformats qt6-wayland qt6-m3shapes-git
  ddcutil brightnessctl libcava aubio lm_sensors libpipewire libqalculate
  networkmanager power-profiles-daemon
  ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
  swappy fish
)

# Only needed to compile the QML plugin.
build_pkgs=(cmake ninja qt6-shadertools gcc git)

# The CLI. Pulls its own colour pipeline (python-materialyoucolor, dart-sass) and
# the tools its subcommands shell out to (cliphist, grim, slurp, wl-clipboard,
# gpu-screen-recorder, fuzzel, libnotify).
cli_pkgs=(caelestia-cli)

# Selected by name via dconf by the CLI, which depends on neither; a missing GTK
# theme falls back to stock Adwaita, which is light.
theme_pkgs=(adw-gtk-theme papirus-icon-theme)

log INFO "Installing caelestia runtime dependencies..."
install_packages "${runtime_pkgs[@]}"

log INFO "Installing build dependencies..."
install_packages "${build_pkgs[@]}"

log INFO "Installing the caelestia CLI..."
install_packages "${cli_pkgs[@]}"

log INFO "Installing the GTK and icon themes the CLI selects..."
install_packages "${theme_pkgs[@]}"

# These arrive as dependencies of nothing, so pacman lists them as orphans and a
# later -Qdt sweep would take the runtime out from under us.
log INFO "Marking runtime dependencies as explicitly installed..."
sudo pacman -D --asexplicit "${runtime_pkgs[@]}" >/dev/null 2>&1 || \
  log WARN "could not mark all runtime packages explicit; check 'pacman -Qdt' before any orphan sweep"

# ---------------------------------------------------------------------------
# Source
# ---------------------------------------------------------------------------

if [ -d "$SHELL_DIR/.git" ]; then
  log INFO "Updating the caelestia shell source in $SHELL_DIR..."
  git -C "$SHELL_DIR" pull --ff-only || \
    log WARN "could not fast-forward; you have local commits or uncommitted changes. Resolve by hand."
elif [ -e "$SHELL_DIR" ]; then
  log ERROR "$SHELL_DIR exists but is not a git clone. Move it aside and re-run."
  exit 1
else
  log INFO "Cloning the caelestia shell into $SHELL_DIR..."
  mkdir -p "$(dirname "$SHELL_DIR")"
  git clone "$SHELL_REPO" "$SHELL_DIR"
fi

# ---------------------------------------------------------------------------
# Plugin
# ---------------------------------------------------------------------------
#
# Built out of tree: the precompiled headers alone are ~1.7G.
#
# CMAKE_INSTALL_PREFIX=$HOME/.local puts the library and the QML plugin under one
# prefix, so no sudo is needed and the README's INSTALL_LIBDIR/CAELESTIA_LIB_DIR
# pairing does not apply. ENABLE_MODULES skips installing a second copy of the QML
# config -- the clone above already is the config directory.

log INFO "Building the caelestia QML plugin (prefix: $PREFIX)..."
cmake -S "$SHELL_DIR" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DENABLE_MODULES="extras;plugin"

cmake --build "$BUILD_DIR"
cmake --install "$BUILD_DIR"

log INFO "Installed $(wc -l < "$BUILD_DIR/install_manifest.txt") plugin files."

# ---------------------------------------------------------------------------
# Notification bus
# ---------------------------------------------------------------------------
#
# 01-install-core.sh installs swaync, and D-Bus starts it on demand the first time
# anything sends a notification; `systemctl disable` does not prevent that. If it wins
# the race, caelestia cannot register org.freedesktop.Notifications and its popups never
# appear. Masking is what blocks it: dbus-broker always activates through systemd, and a
# masked unit refuses to start. .config/systemd is stowed, so the mask is the tracked
# link .config/systemd/user/swaync.service -> /dev/null and is normally already in
# place; this makes sure. uninstall-caelestia.sh unmasks it.

if systemctl --user cat swaync.service >/dev/null 2>&1; then
  log INFO "Masking swaync.service so caelestia owns the notification bus..."
  if systemctl --user mask swaync.service >/dev/null 2>&1; then
    systemctl --user stop swaync.service >/dev/null 2>&1 || true
  else
    log WARN "could not mask swaync.service (no user session?); run: systemctl --user mask --now swaync"
  fi
fi

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

if command -v caelestia >/dev/null 2>&1; then
  log SUCCESS "caelestia CLI on PATH: $(command -v caelestia)"
else
  log WARN "caelestia not on PATH -- is ~/.local/bin ahead of /usr/bin, shadowing it?"
fi

log SUCCESS "Installed. Start the shell with: caelestia shell -d"
log INFO "Qt does not search $PREFIX/lib/qt6/qml by default; UserConfigs/user_env.lua"
log INFO "sets QML_IMPORT_PATH and QML2_IMPORT_PATH so the plugin is found."
log INFO "Local changes: edit QML in $SHELL_DIR and check 'git -C \"$SHELL_DIR\" diff'."
