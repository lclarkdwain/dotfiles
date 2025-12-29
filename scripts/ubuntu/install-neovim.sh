#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

log INFO "Installing Neovim build dependencies..."
sudo apt install -y \
    ninja-build \
    gettext \
    cmake \
    curl \
    build-essential

log INFO "Building Neovim from source..."
NEOVIM_SRC="$HOME/src/neovim"
mkdir -p "$HOME/src"

if [ -d "$NEOVIM_SRC" ]; then
    log INFO "Neovim source already exists, pulling latest changes..."
    cd "$NEOVIM_SRC"
    git pull
else
    git clone https://github.com/neovim/neovim "$NEOVIM_SRC"
    cd "$NEOVIM_SRC"
fi

make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
log SUCCESS "Neovim installed: $(nvim --version | head -n 1)"
cd ~

log INFO "Installing LazyVim dependencies..."
sudo apt install -y \
    fzf \
    ripgrep \
    fd-find

log SUCCESS "Neovim and LazyVim dependencies installed"