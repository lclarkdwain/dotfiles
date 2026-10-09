#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

# GitHub's apt repo; Ubuntu's own gh package lags far behind
KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
SOURCES="/etc/apt/sources.list.d/github-cli.list"

log INFO "Adding the GitHub CLI apt repository..."
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee "$KEYRING" >/dev/null
sudo chmod go+r "$KEYRING"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" |
  sudo tee "$SOURCES" >/dev/null

log INFO "Installing GitHub CLI..."
sudo apt update
sudo apt install -y gh

if command -v gh &>/dev/null; then
  log SUCCESS "GitHub CLI installed: $(gh --version | head -n 1)"
  log INFO "Run gh auth login to sign in"
else
  log ERROR "GitHub CLI installation failed"
  exit 1
fi
