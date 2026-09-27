#!/bin/bash

zsh_pkgs=(
  zsh
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${zsh_pkgs[@]}"

# Login shell; foot sets shell=zsh itself, other terminals and the TTY use this
zsh_path=$(command -v zsh || true)
if [ -z "$zsh_path" ]; then
  log ERROR "zsh is not installed; login shell unchanged."
  exit 1
elif [ "$(getent passwd "$(whoami)" | cut -d: -f7)" = "$zsh_path" ]; then
  log INFO "Login shell is already {GREEN}zsh{RESET}."
else
  sudo chsh -s "$zsh_path" "$(whoami)"
  log OK "Login shell changed to {GREEN}zsh{RESET}. Takes effect on next login."
fi
