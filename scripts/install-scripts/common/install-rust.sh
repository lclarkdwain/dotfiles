#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

DOTFILES="$HOME/.dotfiles"

log INFO "Installing Rust and Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Source cargo env for current session
source "$HOME/.cargo/env"
log SUCCESS "Rust and Cargo installed: $(rustc --version)"

# Install Rust packages from file
RUST_PKGS_FILE="$DOTFILES/packages/rust"
if [ -f "$RUST_PKGS_FILE" ]; then
  log INFO "Installing Rust packages from $RUST_PKGS_FILE..."

  # Read packages and install them
  while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue

    log INFO "Installing Rust package: $package"
    # --locked builds against the crate's own Cargo.lock. Without it cargo picks
    # the newest semver-compatible deps, which can be a combination the crate
    # never tested -- eza 0.23.5 failed to compile that way (palette 0.7.5 with a
    # newer palette_derive).
    cargo install --locked "$package" || log WARN "Failed to install $package, continuing..."
  done <"$RUST_PKGS_FILE"

  log SUCCESS "Rust packages installation complete"
else
  log WARN "No packages file found at $RUST_PKGS_FILE; skipping cargo install"
fi
