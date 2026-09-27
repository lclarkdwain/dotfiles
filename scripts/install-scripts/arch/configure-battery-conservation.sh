#!/bin/bash

# Lenovo battery conservation mode: the firmware stops charging at ~80% on AC.
# Off for a full charge: echo Standard | sudo tee /sys/class/power_supply/BAT*/charge_types
# Off for good: also remove the udev rule below.

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

rule="/etc/udev/rules.d/90-lenovo-conservation-mode.rules"
match='ACTION=="bind", SUBSYSTEM=="platform", DRIVER=="ideapad_acpi"'

# charge_types is the standard interface; ideapad's conservation_mode is deprecated
charge_types=$(grep -l 'Long_Life' /sys/class/power_supply/BAT*/charge_types 2>/dev/null | head -n1)
conservation_mode=$(compgen -G "/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode" | head -n1)

if [ -n "$charge_types" ]; then
  target="$charge_types"
  value="Long_Life"
  # Reapplied whenever the driver loads, in case the firmware forgets it
  rule_line="$match, RUN+=\"/bin/sh -c 'echo Long_Life > $charge_types'\""
elif [ -n "$conservation_mode" ]; then
  target="$conservation_mode"
  value="1"
  rule_line="$match, ATTR{conservation_mode}=\"1\""
else
  log NOTE "This machine has no Lenovo conservation mode; skipping."
  exit 0
fi

echo "$rule_line" | sudo tee "$rule" >/dev/null
log OK "Wrote $rule."

echo "$value" | sudo tee "$target" >/dev/null
if grep -qE "^1$|\[Long_Life\]" "$target"; then
  log OK "Battery conservation mode is {GREEN}on{RESET} ($target)."
else
  log WARN "Could not enable conservation mode. Check: cat $target"
fi
