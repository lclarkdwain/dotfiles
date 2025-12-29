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
fi

log INFO "Installing NVM (Node Version Manager)..."

# NVM will automatically use $XDG_CONFIG_HOME/nvm if XDG_CONFIG_HOME is set which in this case from sourced .zshenv
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'

# Source NVM for current session
export NVM_DIR="$XDG_CONFIG_HOME/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
  log SUCCESS "NVM installed: $(nvm --version)"

  log INFO "Installing latest LTS version of Node.js..."
  nvm install --lts
  nvm alias default 'lts/*'
  log SUCCESS "Node.js installed: $(node --version)"
else
  log ERROR "NVM installation failed"
  exit 1
fi

