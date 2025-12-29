#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

DOTFILES="$HOME/.dotfiles"
ZSHENV="$DOTFILES/zsh/.zshenv"

if [ -f "$ZSHENV" ]; then
  source "$ZSHENV"
  log INFO "Loaded environment from .zshenv"
fi

log INFO "Updating package lists..."
sudo apt update

# Prompt for upgrade
printf "\n"
read -rp "Do you want to upgrade existing packages? This may take a while [y/N]: " upgrade_response
upgrade_response=${upgrade_response,,}

if [[ "$upgrade_response" == "y" || "$upgrade_response" == "yes" ]]; then
  log INFO "Upgrading existing packages..."
  sudo apt upgrade -y
  log SUCCESS "Package upgrade complete"
else
  log INFO "Skipping package upgrade"
fi

log INFO "Installing essential tools..."
sudo apt install -y \
  python3-venv \
  stow \
  unzip \
  curl \
  git \
  zsh

log INFO "Initializing git submodules..."
git submodule update --init

log SUCCESS "System updates and essential tools installed"
