#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

UDEV_RULE="/etc/udev/rules.d/99-rapl-access.rules"

# Trade-off: exposing energy_uj re-opens CVE-2020-8694, a power side-channel that
# needs an attacker already running local code as you. Group wheel, not world.
if [ -f "$UDEV_RULE" ]; then
  log WARN "$UDEV_RULE already exists; leaving it untouched"
else
  log INFO "Writing $UDEV_RULE..."
  sudo tee "$UDEV_RULE" >/dev/null <<'RULE'
# Let wheel read RAPL energy counters so sysmon-sample can report CPU package watts.
SUBSYSTEM=="powercap", ACTION=="add", RUN+="/bin/sh -c 'chgrp wheel /sys%p/energy_uj && chmod 0440 /sys%p/energy_uj'"
RULE
  log SUCCESS "udev rule written"
fi

log INFO "Applying to already-registered powercap devices..."
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=powercap --action=add

if [ -r /sys/class/powercap/intel-rapl:0/energy_uj ]; then
  log SUCCESS "CPU package energy readable: $(cat /sys/class/powercap/intel-rapl:0/energy_uj) uJ"
else
  log WARN "energy_uj still unreadable; sysmon will report CPU watts as unavailable"
fi
