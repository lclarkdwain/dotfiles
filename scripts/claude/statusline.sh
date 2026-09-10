#!/usr/bin/env bash
set -uo pipefail

side=${1:-unknown}
payload=$(cat)

case $side in
  work)     state=$HOME/.claude.json
            label=WORK      ; accent=$'\033[38;5;209m' ;;
  personal) state=${CLAUDE_PERSONAL_CONFIG_DIR:-$HOME/.claude-personal}/.claude.json
            label=PERSONAL  ; accent=$'\033[38;5;79m'  ;;
  *)        state=; label=${side^^}; accent=$'\033[38;5;244m' ;;
esac

dim=$'\033[38;5;244m'; reset=$'\033[0m'

command -v jq >/dev/null 2>&1 && _jq=1 || _jq=

field() {
  [[ -n ${_jq:-} ]] || return 0
  printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null
}

email=
if [[ -n $state && -r $state ]]; then
  if [[ -n $_jq ]]; then
    email=$(jq -r '.oauthAccount.emailAddress // empty' "$state" 2>/dev/null)
  else
    email=$(sed -n 's/.*"emailAddress"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$state" | head -1)
  fi
fi

cwd=$(field '.workspace.current_dir')
model=$(field '.model.display_name')
[[ -n $cwd ]] && cwd=${cwd##*/}

line="${accent}● ${label}${reset}"
[[ -n $email ]] && line+="${dim}  ${email}${reset}"
[[ -n $cwd   ]] && line+="${dim} · ${cwd}${reset}"
[[ -n $model ]] && line+="${dim} · ${model}${reset}"
printf '%s' "$line"
