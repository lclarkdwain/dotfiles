#!/usr/bin/env bash

SOURCE="https://github.com/lclarkdwain/dotfiles"
TARGET="$HOME/.dotfiles"

if type "git" > /dev/null 2>&1; then
  echo "Installing dotfiles..."
  mkdir -p "$TARGET"
  eval "git clone $SOURCE $TARGET"
fi