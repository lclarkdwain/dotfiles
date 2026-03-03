#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

log INFO "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  log SUCCESS "Default shell changed to zsh"
  log INFO "Log back in for changes to take effect"
else
  log INFO "Default shell is already zsh"
fi

