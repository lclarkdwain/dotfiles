#!/usr/bin/env bash

# Detection helpers.
#
# NVIDIA env vars used to be enabled here by sed-editing the hyprlang
# ENVariables.conf. configs/system_env.lua now detects the driver at load time,
# so there is nothing for the installer to adjust.

# Decide waybar config/style based on chassis type. Echoes chosen config path.
detect_waybar_config() {
  if hostnamectl | grep -q 'Chassis: desktop'; then
    echo "desktop"
  else
    echo "laptop"
  fi
}
