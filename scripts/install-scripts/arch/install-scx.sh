#!/bin/bash

# scx_lavd via scx_loader. System-wide, so it has its own opt-in in install-arch.sh.
# Disable: sudo systemctl disable --now scx_loader

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

if [ ! -d /sys/kernel/sched_ext ]; then
  log NOTE "This kernel has no sched_ext support; skipping scx_lavd."
  exit 0
fi

install_pacman_packages scx-scheds scx-tools

scx_conf="/etc/scx_loader/config.toml"
if [ -f "$scx_conf" ]; then
  log WARN "$scx_conf already exists; leaving it untouched."
else
  sudo mkdir -p "$(dirname "$scx_conf")"
  sudo tee "$scx_conf" >/dev/null <<'CONF'
default_sched = "scx_lavd"
default_mode = "Auto"
CONF
  log OK "Wrote $scx_conf."
fi

if sudo systemctl enable --now scx_loader.service; then
  log OK "{GREEN}scx_loader{RESET} enabled."
else
  log WARN "Could not enable scx_loader. Check: systemctl status scx_loader"
fi

# scx_loader starts the scheduler asynchronously.
for _ in 1 2 3 4 5; do
  [ "$(cat /sys/kernel/sched_ext/state 2>/dev/null)" = "enabled" ] && break
  sleep 1
done
if [ "$(cat /sys/kernel/sched_ext/state 2>/dev/null)" = "enabled" ]; then
  log OK "sched_ext active: {GREEN}$(cat /sys/kernel/sched_ext/root/ops 2>/dev/null){RESET}"
else
  log WARN "sched_ext is not active. Check: systemctl status scx_loader"
fi
