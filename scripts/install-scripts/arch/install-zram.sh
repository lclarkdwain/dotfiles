#!/bin/bash

set -e

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

ZRAM_CONF="/etc/systemd/zram-generator.conf"
SYSCTL_CONF="/etc/sysctl.d/99-zram.conf"

# No swap on this machine means tmpfs pressure (/tmp is RAM-backed) escalates
# straight to OOM kills instead of degrading. zram gives the kernel a lever.
log INFO "Installing zram-generator..."
sudo pacman -S --needed --noconfirm zram-generator

if [ -f "$ZRAM_CONF" ]; then
  log WARN "$ZRAM_CONF already exists; leaving it untouched"
else
  log INFO "Writing $ZRAM_CONF..."
  sudo tee "$ZRAM_CONF" >/dev/null <<'CONF'
[zram0]
zram-size = min(ram / 4, 8192)
compression-algorithm = zstd
CONF
  log SUCCESS "zram configured"
fi

# Arch's zram-generator ships no sysctl drop-in, so these sit at disk-swap
# defaults: swappiness 60 makes the kernel reluctant to use what is actually
# RAM-speed swap, and page-cluster 3 reads 8 pages per fault to amortise disk
# seeks that zram does not have.
if [ -f "$SYSCTL_CONF" ]; then
  log WARN "$SYSCTL_CONF already exists; leaving it untouched"
else
  log INFO "Writing $SYSCTL_CONF..."
  sudo tee "$SYSCTL_CONF" >/dev/null <<'CONF'
vm.swappiness = 180
vm.page-cluster = 0
CONF
  sudo sysctl --system >/dev/null
  log SUCCESS "vm tuning applied: swappiness=$(sysctl -n vm.swappiness), page-cluster=$(sysctl -n vm.page-cluster)"
fi

# The generator only emits its units on daemon-reload, and nothing loads the
# zram module on its own (no modules-load.d ships with the package), so a fresh
# install needs both before /dev/zram0 exists. Without this it only comes up
# after a reboot.
log INFO "Activating zram..."
sudo systemctl daemon-reload

if ! sudo modprobe zram; then
  log WARN "Could not load the zram module; zram will activate on next boot"
elif sudo systemctl start systemd-zram-setup@zram0.service; then
  log SUCCESS "zram active: $(swapon --show=NAME,SIZE --noheadings | tr '\n' ' ')"
else
  log WARN "zram setup failed to start; check: systemctl status systemd-zram-setup@zram0.service"
fi
