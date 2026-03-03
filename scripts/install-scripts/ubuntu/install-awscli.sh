#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

log INFO "Installing AWS CLI v2..."

# Check if AWS CLI is already installed
if command -v aws &>/dev/null; then
  CURRENT_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
  log INFO "AWS CLI is already installed: $CURRENT_VERSION"

  printf "\n"
  read -rp "Do you want to reinstall/update AWS CLI v2? [y/N]: " reinstall_response
  reinstall_response=${reinstall_response,,}

  if [[ "$reinstall_response" != "y" && "$reinstall_response" != "yes" ]]; then
    log INFO "Skipping AWS CLI installation"
    exit 0
  fi
fi

# Download AWS CLI v2
log INFO "Downloading AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the installer
log INFO "Extracting installer..."
unzip -q awscliv2.zip

# Install AWS CLI
log INFO "Installing AWS CLI v2..."
if command -v aws &>/dev/null; then
  # Update existing installation
  sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
else
  # Fresh installation
  sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
fi

# Clean up
log INFO "Cleaning up installation files..."
rm -rf aws awscliv2.zip

# Verify installation
if command -v aws &>/dev/null; then
  log SUCCESS "AWS CLI installed: $(aws --version)"
else
  log ERROR "AWS CLI installation failed"
  exit 1
fi

log INFO "AWS CLI installation complete"
log INFO "Run 'aws configure' to set up your credentials"
