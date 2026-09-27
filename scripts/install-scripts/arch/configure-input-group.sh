#!/bin/bash

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Check if the 'input' group exists
if grep -q '^input:' /etc/group; then
  log OK "{MAGENTA}input{RESET} group exists."
else
  log NOTE "{MAGENTA}input{RESET} group doesn't exist. Creating {MAGENTA}input{RESET} group..."
  sudo groupadd input
  log "{MAGENTA}input{RESET} group created"
fi

# Add the user to the 'input' group
sudo usermod -aG input "$(whoami)"
log OK "{YELLOW}user{RESET} added to the {MAGENTA}input{RESET} group. Changes will take effect after you log out and log back in."

printf "\n%.0s" {1..2}
