#!/bin/bash

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

printf "${INFO} ${SKY_BLUE}blacklist nouveau${RESET}...\n"
# Blacklist nouveau
NOUVEAU="/etc/modprobe.d/nouveau.conf"
if [ -f "$NOUVEAU" ]; then
  printf "${OK} Seems like ${YELLOW}nouveau${RESET} is already blacklisted..moving on.\n"
else
  echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | log PIPE

  # To completely blacklist nouveau (See wiki.archlinux.org/title/Kernel_module#Blacklisting 6.1)
  if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
    echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | log PIPE
  else
    echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | log PIPE
  fi
fi

printf "\n%.0s" {1..2}
