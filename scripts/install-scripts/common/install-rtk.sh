#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

RTK_VERSION="v0.46.0"
RTK_DIR="$HOME/.local/opt/rtk"
ASSET="rtk-x86_64-unknown-linux-musl.tar.gz"
RTK_URL="https://github.com/rtk-ai/rtk/releases/download/$RTK_VERSION/$ASSET"

# Prebuilt release tarball on purpose: `cargo install --git` needs a multi-GB
# build tree and fails on quota-limited /tmp.
log INFO "Installing rtk $RTK_VERSION to $RTK_DIR..."

if [ "$(uname -m)" != "x86_64" ]; then
  log WARN "rtk install script only covers x86_64; skipping on $(uname -m)"
  exit 0
fi

mkdir -p "$RTK_DIR"
if ! curl -fsSL "$RTK_URL" | tar -xz -C "$RTK_DIR"; then
  log ERROR "Failed to download or extract rtk from $RTK_URL"
  exit 1
fi

log SUCCESS "rtk installed: $("$RTK_DIR/rtk" --version)"
