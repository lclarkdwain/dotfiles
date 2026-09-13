#!/usr/bin/env bash
# RainbowBorders-low-cpu.sh — low-overhead animated rainbow border for Hyprland
#
# Goal
#   Animate Hyprland's active border with a rotating rainbow gradient while
#   minimizing CPU usage on older systems by:
#     - Using a modest update rate (default 1.0s) and larger angle steps
#     - Avoiding subshell-heavy work inside the loop
#     - Using Hyprland's command socket via socat when available
#     - Quoting/validating inputs and suppressing noisy output
#     - Preventing multiple concurrent instances
#     - Optionally restoring the previous border value on exit
#
# Credits
#   Initial source/idea by: DemiGoD
#   Adaptation and optimization for low-CPU usage by: Hyprland-Dots maintainers
#
# Usage
#   You can customize behavior via environment variables when launching:
#     RB_INTERVAL    Float seconds between updates (default: 1.0)
#     RB_STEP_DEG    Integer degrees per tick        (default: 10)
#     RB_START_DEG   Integer starting angle          (default: 0)
#     RB_TARGET      Hypr option to update           (default: general:col.active_border)
#     RB_COLORS      Space-separated color list      (default: 10-color rainbow below)
#     RB_RESTORE     If "1", attempt to restore previous value on exit (loop mode; default: 1)
#     RB_LOCKFILE    Path to a PID lock file         (loop mode; default: /tmp/hypr-rainbowborders.lock)
#     RB_TRANSPORT   auto|socat|hyprctl              (default: auto)
#                      - socat: send each command via Hyprland's command socket
#                        using socat (one short-lived connection per tick)
#                      - hyprctl: spawn hyprctl each tick
#                      - auto: prefer socat if possible, otherwise hyprctl
#     RB_ONCE        1 to apply once and exit (no animation; default: 0)
#
#   Example (slower animation):
#     RB_INTERVAL=1.5 RB_STEP_DEG=12 ~/.config/hypr/UserScripts/RainbowBorders-low-cpu.sh &
#
# Notes
#   - This focuses on the active border only. Animating inactive borders too
#     will increase updates and CPU usage.
#   - Higher RB_INTERVAL (e.g., 1.0–2.0s) and larger RB_STEP_DEG (10–20)
#     reduce per-second work substantially.

set -u

# Defaults (can be overridden by env vars)
RB_INTERVAL="${RB_INTERVAL:-1.0}"
RB_STEP_DEG="${RB_STEP_DEG:-10}"
RB_START_DEG="${RB_START_DEG:-0}"
RB_TARGET="${RB_TARGET:-general:col.active_border}"
RB_COLORS_DEFAULT="0xffff0000 0xffff8000 0xffffff00 0xff80ff00 0xff00ff00 0xff00ff80 0xff00ffff 0xff0080ff 0xff0000ff 0xff8000ff"
RB_COLORS="${RB_COLORS:-$RB_COLORS_DEFAULT}"
RB_RESTORE="${RB_RESTORE:-1}"
RB_LOCKFILE="${RB_LOCKFILE:-/tmp/hypr-rainbowborders.lock}"
RB_TRANSPORT="${RB_TRANSPORT:-auto}"
RB_ONCE="${RB_ONCE:-0}"

# ---------- helpers ----------
log() { printf '[RainbowBorders-low-cpu] %s\n' "$*" >&2; }

die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<'EOF'
Usage: RainbowBorders-low-cpu.sh [options]

Options:
  -h, --help     Show this help and exit
  --once, --run-once, -1
                 Apply the current gradient once and exit (no animation).
                 In this mode, RB_RESTORE is ignored (the color persists).

Environment overrides:
  RB_INTERVAL    Seconds between updates (default: 1.0)
  RB_STEP_DEG    Degrees per tick (default: 10)
  RB_START_DEG   Starting angle (default: 0)
  RB_TARGET      Hypr option to update (default: general:col.active_border)
  RB_COLORS      Space-separated colors (default: 10-color rainbow)
  RB_RESTORE     1 to restore previous value on exit (loop mode only; default: 1)
  RB_LOCKFILE    PID lock path (loop mode only; default: /tmp/hypr-rainbowborders.lock)
  RB_TRANSPORT   auto|socat|hyprctl (default: auto)
  RB_ONCE        1 for one-shot mode (same as --once)

Examples:
  Animate (light CPU):
    RB_INTERVAL=1.5 RB_STEP_DEG=12 ./RainbowBorders-low-cpu.sh &

  Set a static rainbow once (no animation):
    ./RainbowBorders-low-cpu.sh --once
EOF
}

is_float() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$|^\.[0-9]+$ ]]; }

is_int()   { [[ "$1" =~ ^[0-9]+$ ]]; }

# ---------- parse CLI flags ----------
while (( $# )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --once|--run-once|-1) RB_ONCE=1 ;;
    *) log "Unknown option: $1"; usage; exit 2 ;;
  esac
  shift
done

# ---------- validation ----------
if ! is_float "$RB_INTERVAL"; then
  log "WARN: RB_INTERVAL='$RB_INTERVAL' invalid; defaulting to 1.0"
  RB_INTERVAL="1.0"
fi
if ! is_int "$RB_STEP_DEG"; then
  log "WARN: RB_STEP_DEG='$RB_STEP_DEG' invalid; defaulting to 10"
  RB_STEP_DEG="10"
fi
if ! is_int "$RB_START_DEG"; then
  log "WARN: RB_START_DEG='$RB_START_DEG' invalid; defaulting to 0"
  RB_START_DEG="0"
fi

# ---------- single-instance lock (PID file) ----------
cleanup_lock() { [[ -f "$RB_LOCKFILE" ]] && rm -f "$RB_LOCKFILE"; }

if [[ "$RB_ONCE" != "1" ]]; then
  if [[ -f "$RB_LOCKFILE" ]]; then
    oldpid="$(cat "$RB_LOCKFILE" 2>/dev/null || true)"
    if [[ -n "${oldpid:-}" ]] && kill -0 "$oldpid" 2>/dev/null; then
      log "Another instance is running (pid=$oldpid). Exiting."
      exit 0
    else
      # Stale lock
      rm -f "$RB_LOCKFILE" || true
    fi
  fi
  printf '%d' "$$" >"$RB_LOCKFILE" 2>/dev/null || die "Cannot write lockfile $RB_LOCKFILE"
fi

# ---------- transport (socat vs hyprctl) ----------
RB_MODE=""
RB_SOCK=""

open_transport() {
  local want="$RB_TRANSPORT"
  local uid; uid=$(id -u 2>/dev/null || echo 0)
  local base="${XDG_RUNTIME_DIR:-/run/user/$uid}"
  local sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
  if [[ -n "$sig" ]]; then
    RB_SOCK="$base/hypr/$sig/.socket.sock"
  fi

  # Prefer socat if requested/allowed and socket is available
  if [[ "$want" == "socat" || "$want" == "auto" ]]; then
    if command -v socat >/dev/null 2>&1 && [[ -n "$RB_SOCK" && -S "$RB_SOCK" ]]; then
      RB_MODE="socat"
      return 0
    elif [[ "$want" == "socat" ]]; then
      die "RB_TRANSPORT=socat requested but 'socat' or Hyprland socket is unavailable"
    fi
  fi

  # Fallback to hyprctl: require presence and connectivity
  command -v hyprctl >/dev/null 2>&1 || die "hyprctl not found and socat transport unavailable"
  if ! hyprctl monitors >/dev/null 2>&1; then
    die "hyprctl cannot reach a running Hyprland instance"
  fi
  RB_MODE="hyprctl"
  return 0
}

open_transport || exit 1
log "Using transport: $RB_MODE"

# ---------- optional restore of previous border value ----------
PREV_VALUE=""
if [[ "$RB_RESTORE" == "1" && "$RB_ONCE" != "1" ]]; then
  if command -v hyprctl >/dev/null 2>&1; then
    # LOCAL FIX: gradient options are reported as `gradient data: <colors> <n>deg`
    # (JSON key "gradient"), which the previous sed for str:/string:/value:
    # never matched -- so PREV_VALUE was always empty and restore was a no-op.
    PREV_VALUE="$(hyprctl -j getoption "$RB_TARGET" 2>/dev/null \
                    | jq -r '.gradient // .str // .custom // empty' 2>/dev/null)"
  fi
fi

restore_previous() {
  if [[ "$RB_RESTORE" == "1" && -n "${PREV_VALUE:-}" ]]; then
    # PREV_VALUE looks like "ff2bc8e4 0deg" (possibly several colours). A bare
    # string is rejected ("invalid color"), so rebuild the HL.Gradient table:
    # bare hex needs an 0x prefix, and the trailing <n>deg becomes a number.
    local expr key colors angle tok
    key="${RB_TARGET//:/.}"
    colors=""
    angle="0"
    for tok in $PREV_VALUE; do
      if [[ "$tok" =~ ^([0-9]+)deg$ ]]; then
        angle="${BASH_REMATCH[1]}"
      elif [[ "$tok" =~ ^(0x|rgba?\() ]]; then
        colors+="\"$tok\","
      elif [[ "$tok" =~ ^[0-9a-fA-F]{6,8}$ ]]; then
        colors+="\"0x$tok\","
      fi
    done
    [[ -z "$colors" ]] && return 0
    expr="$(printf 'hl.config({ ["%s"] = { colors = {%s}, angle = %s } })' "$key" "${colors%,}" "$angle")"
    if [[ "$RB_MODE" == "socat" ]]; then
      printf 'eval %s\n' "$expr" | socat - "UNIX-CONNECT:$RB_SOCK" >/dev/null 2>&1 || true
    else
      hyprctl eval "$expr" >/dev/null 2>&1 || true
    fi
  fi
}

on_exit() {
  restore_previous
  cleanup_lock
}

# In loop mode, set traps for cleanup/restore
if [[ "$RB_ONCE" != "1" ]]; then
  trap on_exit INT TERM EXIT
fi

# ---------- main logic ----------
angle=$(( RB_START_DEG % 360 ))
STEP=$(( RB_STEP_DEG % 360 ))
(( STEP == 0 )) && STEP=10

# LOCAL FIX for Hyprland Lua configs: "keyword" is rejected by the Lua parser
# ("keyword can't work with non-legacy parsers. Use eval."), so every border
# write silently failed. Build an hl.config() call instead and send it via
# "eval". Both transports accept it: `hyprctl eval <lua>` and `eval <lua>` on
# the command socket. HL.Gradient is `string|{colors:string[], angle?:number}`,
# so the colour list becomes a Lua table and the angle a number.
# Hypr option paths use ':' separators; Lua config keys use '.'.
lua_border_expr() {
  local a="$1" key colors c
  key="${RB_TARGET//:/.}"
  colors=""
  for c in $RB_COLORS; do
    colors+="\"$c\","
  done
  printf 'hl.config({ ["%s"] = { colors = {%s}, angle = %s } })' "$key" "${colors%,}" "$a"
}

write_border() {
  local a="$1" expr
  expr="$(lua_border_expr "$a")"
  if [[ "$RB_MODE" == "socat" ]]; then
    printf 'eval %s\n' "$expr" | socat - "UNIX-CONNECT:$RB_SOCK" >/dev/null 2>&1 || true
  else
    hyprctl eval "$expr" >/dev/null 2>&1 || true
  fi
}

if [[ "$RB_ONCE" == "1" ]]; then
  # Single write and exit; do not restore previous (intended to persist)
  write_border "$angle" || log "WARN: one-shot write failed"
  exit 0
fi

# Prime first write (avoid waiting one interval)
write_border "$angle" || log "WARN: initial write failed"

while :; do
  # Advance angle and write; failures are non-fatal to keep CPU use minimal
  angle=$(( (angle + STEP) % 360 ))
  write_border "$angle"
  sleep "$RB_INTERVAL"
done
