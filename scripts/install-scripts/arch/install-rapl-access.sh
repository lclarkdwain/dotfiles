#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

UDEV_RULE="/etc/udev/rules.d/99-rapl-access.rules"

# Exposes energy_uj (CVE-2020-8694 power side-channel) to wheel only, not world.
# KERNEL== skips the parent "intel-rapl" control device, which has no energy_uj
# and made the rule fail once per boot.
RULE_CONTENT='# Let wheel read RAPL energy counters (CPU package watts)
SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", ACTION=="add", RUN+="/bin/sh -c '"'"'chgrp wheel /sys%p/energy_uj && chmod 0440 /sys%p/energy_uj'"'"'"'

# Rewrite a rule that predates the KERNEL== match, so machines carrying the old
# version pick up the fix by re-running this script.
if [ -f "$UDEV_RULE" ] && grep -qF 'KERNEL=="intel-rapl:*"' "$UDEV_RULE"; then
  log INFO "$UDEV_RULE is up to date"
else
  log INFO "Writing $UDEV_RULE..."
  printf '%s\n' "$RULE_CONTENT" | sudo tee "$UDEV_RULE" >/dev/null
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
