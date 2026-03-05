#!/usr/bin/env bash

# Detection and environment adjustment helpers.
# Nvidia tweaks: uncomments envs and adjusts hardware cursor setting.

detect_nvidia_adjust() {
  if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    echo "${INFO:-[INFO]} Nvidia GPU detected. Setting up proper env's and configs" 2>&1 | log PIPE || true
    sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' .config/hypr/configs/ENVariables.conf
    sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' .config/hypr/configs/ENVariables.conf
    sed -i '/env = NVD_BACKEND,direct/s/^#//' .config/hypr/configs/ENVariables.conf
    sed -i '/env = GSK_RENDERER,ngl/s/^#//' .config/hypr/configs/ENVariables.conf
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' .config/hypr/configs/SystemSettings.conf
  fi
}

# VM tweaks: enable software renderer envs and virtual monitor defaults.
detect_vm_adjust() {
  if hostnamectl | grep -q 'Chassis: vm'; then
    echo "${INFO:-[INFO]} System is running in a virtual machine. Setting up proper env's and configs" 2>&1 | log PIPE || true
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' .config/hypr/configs/SystemSettings.conf
    sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' .config/hypr/configs/ENVariables.conf
    sed -i '/monitor = Virtual-1, 1920x1080@60,auto,1/s/^#//' .config/hypr/monitors.conf
  fi
}

# Decide waybar config/style based on chassis type. Echoes chosen config path.
detect_waybar_config() {
  if hostnamectl | grep -q 'Chassis: desktop'; then
    echo "desktop"
  else
    echo "laptop"
  fi
}
