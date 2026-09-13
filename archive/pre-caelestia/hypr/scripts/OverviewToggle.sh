#!/usr/bin/env bash
# Overview toggle wrapper - tries Quickshell first, falls back to AGS

set -euo pipefail

# 1) Try Quickshell via IPC (works if QS is running and listening)
# LOCAL FIX: started as `qs`, the process name is "qs", not "quickshell", so a
# `pgrep -x quickshell` check never matched and every press launched another
# overview instance below.
if pgrep -x 'qs|quickshell' >/dev/null 2>&1; then
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# If QS isn't running, but the CLI exists, try starting it and retry once.
# --no-duplicate: never stack a second instance on a live one.
if command -v qs >/dev/null 2>&1; then
  qs -n -c overview >/dev/null 2>&1 &
  sleep 0.6
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# 2) Fall back to AGS template
if command -v ags >/dev/null 2>&1; then
  pkill rofi || true
  if ags -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
  # If it failed, try starting AGS daemon then call the template
  ags >/dev/null 2>&1 &
  sleep 0.6
  if ags -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
fi

# If we get here, neither worked
notify-send "Overview" "Neither Quickshell nor AGS is available" -u low 2>/dev/null || true
exit 1
