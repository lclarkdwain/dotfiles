#!/bin/bash

bluetooth_pkgs=(
  blueman
  bluez
  bluez-utils
)

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

install_packages "${bluetooth_pkgs[@]}"

printf " Activating ${tput_colors[YELLOW]}Bluetooth${tput_colors[RESET]} Services...\n"
sudo systemctl enable --now bluetooth.service 2>&1 | log PIPE

# BlueZ pairs devices as Trusted: no, and an untrusted device will not
# auto-reconnect when it powers on -- it has to be reconnected by hand from
# Blueman every session. Trust whatever is already paired so a re-run, or a
# machine whose /var/lib/bluetooth was restored, ends up in the right state.
#
# This CANNOT fix future pairings: BlueZ has no "trust by default" setting and
# trust is per-device. Anything paired after this runs still needs a one-off
#   bluetoothctl trust <mac>
# or the equivalent toggle in Blueman's device menu.
if command -v bluetoothctl >/dev/null 2>&1; then
  paired_devices=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}' || true)

  if [ -z "$paired_devices" ]; then
    log NOTE "No paired Bluetooth devices yet. After pairing one, run {SKY_BLUE}bluetoothctl trust <mac>{RESET} or it will not auto-reconnect on boot."
  else
    for mac in $paired_devices; do
      if bluetoothctl info "$mac" 2>/dev/null | grep -q "Trusted: yes"; then
        log OK "Bluetooth device {MAGENTA}$mac{RESET} is already trusted."
      elif bluetoothctl trust "$mac" >/dev/null 2>&1; then
        log OK "Trusted Bluetooth device {MAGENTA}$mac{RESET}; it will now auto-reconnect."
      else
        log WARN "Could not trust Bluetooth device {MAGENTA}$mac{RESET}."
      fi
    done
  fi
fi
