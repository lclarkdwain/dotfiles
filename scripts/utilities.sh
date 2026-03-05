#!/bin/bash

set -e

declare -A color_map=(
  [BLACK]="30" [RED]="31" [GREEN]="32" [YELLOW]="33"
  [BLUE]="34" [MAGENTA]="35" [CYAN]="36" [LIGHT_GRAY]="37"

  [ORANGE]="38;5;208" [DARK_ORANGE]="38;5;202" [GOLD]="38;5;214" [LIME]="38;5;82"
  [SKY_BLUE]="38;5;45" [TEAL]="38;5;33" [PURPLE]="38;5;129" [CRIMSON]="38;5;160"

  [DARK_GRAY]="90" [WHITE]="97"

  [BACKGROUND_ORANGE]="48;5;208"

  [RESET]="0"
)

declare -A tput_colors=(
  [BLACK]=$(tput setaf 0) [RED]=$(tput setaf 1) [GREEN]=$(tput setaf 2) [YELLOW]=$(tput setaf 3)
  [BLUE]=$(tput setaf 4) [MAGENTA]=$(tput setaf 5) [CYAN]=$(tput setaf 6) [LIGHT_GRAY]=$(tput setaf 7)

  [DARK_GRAY]=$(tput setaf 8) [WHITE]=$(tput setaf 15)

  [ORANGE]=$(tput setaf 208) [DARK_ORANGE]=$(tput setaf 202) [GOLD]=$(tput setaf 214) [LIME]=$(tput setaf 82)
  [SKY_BLUE]=$(tput setaf 45) [TEAL]=$(tput setaf 33) [PURPLE]=$(tput setaf 129) [CRIMSON]=$(tput setaf 160)

  [BACKGROUND_ORANGE]=$(tput setab 208)

  [RESET]=$(tput sgr0)
)

export tput_colors

OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

log() {
  local level="$1"
  local message=""
  local color=""
  local colorized_message=""
  local script_name
  local log_dir="${DOTFILES:-$HOME/.dotfiles}/logs"
  local log_file

  script_name=$(basename "$0")
  mkdir -p "$log_dir"
  log_file="${log_dir}/${script_name}_$(date '+%Y-%m-%d').log"

  case "$level" in
  ACTION)
    color="${color_map[CYAN]}"
    shift
    ;;
  INFO)
    color="${color_map[BLUE]}"
    shift
    ;;
  OK | SUCCESS)
    color="${color_map[GREEN]}"
    shift
    ;;
  NOTE | WARN | WARNING)
    color="${color_map[YELLOW]}"
    shift
    ;;
  ERROR)
    color="${color_map[RED]}"
    shift
    ;;
  PIPE)
    color="${color_map[DARK_GRAY]}"
    while IFS= read -r line; do
      echo -e "\033[${color}m[PIPE]\033[0m $line\033[0m" | tee >(sed "s/\x1b\[[0-9;]*m//g" | sed "s/^/$(date '+%Y-%m-%d %H:%M:%S') /" >>"$log_file")
    done
    return
    ;;
  PIPE_NO_TERM)
    while IFS= read -r line; do
      echo "[PIPE_NO_TERM] $(date '+%Y-%m-%d %H:%M:%S') $line" >>"$log_file"
    done
    return
    ;;
  *)
    color="${color_map[RESET]}"
    level=""
    ;;
  esac

  message="$*"

  while IFS= read -r -n1 char; do
    case "$char" in
    "{")
      # Extract color label inside braces
      color_label=""
      while IFS= read -r -n1 char && [[ "$char" != "}" ]]; do
        color_label+="$char"
      done
      if [[ -n "${color_map[$color_label]}" ]]; then
        colorized_message+="\033[${color_map[$color_label]}m"
      fi
      ;;
    "}")
      # Ignore closing brace
      ;;
    *)
      colorized_message+="$char"
      ;;
    esac
  done <<<"$message"

  if [ -n "$level" ]; then
    if ! echo -e "\033[${color}m[$level]\033[0m $colorized_message\033[0m" | tee >(sed "s/\x1b\[[0-9;]*m//g" | sed "s/^/$(date '+%Y-%m-%d %H:%M:%S') /" >>"$log_file"); then
      echo "Error: Failed to write log message to file or output." >&2
      exit 1
    fi
  else
    if ! echo -e "$colorized_message\033[0m" | tee >(sed "s/\x1b\[[0-9;]*m//g" | sed "s/^/$(date '+%Y-%m-%d %H:%M:%S') /" >>"$log_file"); then
      echo "Error: Failed to write log message to file or output." >&2
      exit 1
    fi
  fi
}
