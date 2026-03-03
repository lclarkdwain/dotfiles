#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

log INFO "Installing Go..."
GO_VERSION="1.23.5"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"

# Download Go
curl -LO "https://go.dev/dl/${GO_ARCHIVE}"

# Remove old installation and install new
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$GO_ARCHIVE"
rm -f "$GO_ARCHIVE"

# Add Go to PATH for current session
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# Verify Go installation
if command -v go &>/dev/null; then
  log SUCCESS "Go installed: $(go version)"
else
  log ERROR "Go installation failed"
  exit 1
fi

log INFO "Installing lazygit via Go..."
go install github.com/jesseduffield/lazygit@latest

# Verify installation (use full path since it might not be in PATH yet)
if [ -f "$GOPATH/bin/lazygit" ]; then
  log SUCCESS "lazygit installed to $GOPATH/bin/lazygit"
  log INFO "lazygit will be available in PATH after you log out and log back in"
else
  log ERROR "lazygit installation failed"
  exit 1
fi

