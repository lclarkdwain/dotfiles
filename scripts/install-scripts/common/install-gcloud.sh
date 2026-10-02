#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

# Through the package manager rather than Google's install.sh, so updates come
# with the system's and nothing is written into $HOME or the shell rc files.
# Components are managed by the package, so `gcloud components install` is
# disabled; install the matching distro package instead.
log INFO "Installing Google Cloud CLI..."

if command -v gcloud &>/dev/null; then
  log INFO "Google Cloud CLI is already installed: $(gcloud version 2>/dev/null | head -n1)"
  exit 0
fi

DISTRO=$(. /etc/os-release 2>/dev/null && echo "$ID")

case "$DISTRO" in
arch)
  if paru --version &>/dev/null; then
    aur_helper=paru
  elif yay --version &>/dev/null; then
    aur_helper=yay
  else
    log ERROR "No AUR helper found; google-cloud-cli is only in the AUR"
    exit 1
  fi
  "$aur_helper" -S --needed --noconfirm google-cloud-cli
  ;;
ubuntu | debian)
  KEYRING=/usr/share/keyrings/cloud.google.gpg
  SOURCES=/etc/apt/sources.list.d/google-cloud-sdk.list

  sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo gpg --dearmor --yes -o "$KEYRING"
  echo "deb [signed-by=$KEYRING] https://packages.cloud.google.com/apt cloud-sdk main" |
    sudo tee "$SOURCES" >/dev/null
  sudo apt-get update
  sudo apt-get install -y google-cloud-cli
  ;;
*)
  log ERROR "No Google Cloud CLI install path for distro '$DISTRO'"
  exit 1
  ;;
esac

hash -r
if command -v gcloud &>/dev/null; then
  log SUCCESS "Google Cloud CLI installed: $(gcloud version 2>/dev/null | head -n1)"
else
  log ERROR "Google Cloud CLI installation failed"
  exit 1
fi

log INFO "Run 'gcloud init' to authenticate and pick a default project"
