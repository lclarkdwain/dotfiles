#!/bin/bash

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# Keep the hardware clock in UTC and let systemd-timesyncd correct it on every boot
sudo timedatectl set-local-rtc 0
sudo timedatectl set-ntp true
log OK "{MAGENTA}NTP{RESET} enabled; the clock syncs on every boot."

# Windows writes local time to the hardware clock unless told it holds UTC
if command -v efibootmgr >/dev/null 2>&1 && efibootmgr 2>/dev/null | grep -q 'Windows Boot Manager'; then
  log WARN "Windows dual boot detected. Run once in an admin terminal on Windows, or the clock drifts after every Windows boot:"
  log WARN 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f'
fi

printf "\n%.0s" {1..2}
