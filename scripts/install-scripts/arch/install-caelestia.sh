#!/bin/bash
# Caelestia shell: clone upstream into ~/.config/quickshell/caelestia, apply the local
# patches, and build its QML plugin into ~/.local.

set -e

if ! source "$(dirname "$(realpath "$0")")/global_fn.sh"; then
  echo "failed to source global_fn.sh"
  exit 1
fi

SHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
SHELL_REPO="https://github.com/caelestia-dots/shell.git"
PATCH_DIR="$(dirname "$(realpath "$0")")/patches/caelestia-shell"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-plugin-build"
PREFIX="$HOME/.local"

# --- Dependencies -------------------------------------------------------------

runtime_pkgs=(
  quickshell-git
  qt6-base qt6-declarative qt6-imageformats qt6-wayland qt6-m3shapes-git
  ddcutil brightnessctl libcava aubio lm_sensors libpipewire libqalculate
  networkmanager power-profiles-daemon
  ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
  swappy fish # fish: the launcher's calculator runs qalc through it
)

build_pkgs=(cmake ninja qt6-shadertools gcc git)

cli_pkgs=(caelestia-cli)

theme_pkgs=(adw-gtk-theme papirus-icon-theme)

# Tools the caelestia-dots configs call out to
dots_pkgs=(
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk ttf-jetbrains-mono-nerd
  foot btop fastfetch thunar pavucontrol
  gnome-keyring polkit-gnome bluez-utils
  wl-clipboard cliphist trash-cli ydotool hyprpicker gammastep geoclue
)

log INFO "Installing caelestia runtime dependencies..."
install_packages "${runtime_pkgs[@]}"

log INFO "Installing build dependencies..."
install_packages "${build_pkgs[@]}"

log INFO "Installing the caelestia CLI..."
install_packages "${cli_pkgs[@]}"

log INFO "Installing the GTK and icon themes the CLI selects..."
install_packages "${theme_pkgs[@]}"

log INFO "Installing what the caelestia-dots configs depend on..."
install_packages "${dots_pkgs[@]}"

# Keep the runtime out of orphan sweeps
log INFO "Marking runtime dependencies as explicitly installed..."
sudo pacman -D --asexplicit "${runtime_pkgs[@]}" >/dev/null 2>&1 || \
  log WARN "could not mark all runtime packages explicit; check 'pacman -Qdt' before any orphan sweep"

# --- Source -------------------------------------------------------------------

# Patches are uncommitted changes in the clone: removed before a pull, reapplied after.
unapply_patches() {
  local patch
  for patch in "$PATCH_DIR"/*.patch; do
    [ -e "$patch" ] || continue
    if git -C "$SHELL_DIR" apply --reverse --check "$patch" 2>/dev/null; then
      git -C "$SHELL_DIR" apply --reverse "$patch"
    fi
  done
}

apply_patches() {
  local patch name
  for patch in "$PATCH_DIR"/*.patch; do
    [ -e "$patch" ] || continue
    name=$(basename "$patch")
    if git -C "$SHELL_DIR" apply --reverse --check "$patch" 2>/dev/null; then
      log INFO "Patch $name already applied."
    elif git -C "$SHELL_DIR" apply --check "$patch" 2>/dev/null; then
      git -C "$SHELL_DIR" apply "$patch"
      log INFO "Applied patch $name."
    else
      log WARN "Patch $name no longer applies: upstream changed that code. Check whether it is still needed."
    fi
  done
}

if [ -d "$SHELL_DIR/.git" ]; then
  log INFO "Updating the caelestia shell source in $SHELL_DIR..."
  unapply_patches
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

log INFO "Applying local patches to the caelestia shell..."
apply_patches

# --- Plugin -------------------------------------------------------------------

log INFO "Building the caelestia QML plugin (prefix: $PREFIX)..."
cmake -S "$SHELL_DIR" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DENABLE_MODULES="extras;plugin"

cmake --build "$BUILD_DIR"
cmake --install "$BUILD_DIR"

log INFO "Installed $(wc -l < "$BUILD_DIR/install_manifest.txt") plugin files."

# --- Notification bus ---------------------------------------------------------

# Masked, not disabled: D-Bus activation would otherwise start swaync ahead of caelestia.
if systemctl --user cat swaync.service >/dev/null 2>&1; then
  log INFO "Masking swaync.service so caelestia owns the notification bus..."
  if systemctl --user mask swaync.service >/dev/null 2>&1; then
    systemctl --user stop swaync.service >/dev/null 2>&1 || true
  else
    log WARN "could not mask swaync.service (no user session?); run: systemctl --user mask --now swaync"
  fi
fi

# --- ydotool ------------------------------------------------------------------

# The paste-latest bind needs ydotoold running with write access to /dev/uinput.
if ! grep -rqs 'KERNEL=="uinput".*uaccess' /usr/lib/udev/rules.d /etc/udev/rules.d; then
  log INFO "Letting the logged-in user write to /dev/uinput (for ydotool)..."
  echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' |
    sudo tee /etc/udev/rules.d/80-uinput-uaccess.rules >/dev/null
  sudo udevadm control --reload-rules || true
  sudo udevadm trigger --name-match=uinput || true
fi

if systemctl --user cat ydotool.service >/dev/null 2>&1; then
  log INFO "Enabling the ydotool daemon..."
  systemctl --user enable --now ydotool.service >/dev/null 2>&1 || \
    log WARN "could not enable ydotool.service (no user session?); run: systemctl --user enable --now ydotool"
else
  log WARN "ydotool.service not found; start ydotoold yourself or the paste-latest keybind does nothing"
fi

# --- Checks -------------------------------------------------------------------

if command -v caelestia >/dev/null 2>&1; then
  log SUCCESS "caelestia CLI on PATH: $(command -v caelestia)"
else
  log WARN "caelestia not on PATH -- is ~/.local/bin ahead of /usr/bin, shadowing it?"
fi

log SUCCESS "Installed. Start the shell with: caelestia shell -d"
log INFO "Qt does not search $PREFIX/lib/qt6/qml by default; .config/caelestia/hypr-user.lua"
log INFO "sets QML_IMPORT_PATH and QML2_IMPORT_PATH so the plugin is found."
log INFO "Local changes: edit QML in $SHELL_DIR and check 'git -C \"$SHELL_DIR\" diff'."
