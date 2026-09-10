export CLAUDE_PERSONAL_CONFIG_DIR="${CLAUDE_PERSONAL_CONFIG_DIR:-$HOME/.claude-personal}"

(( ${+CLAUDE_WORK_ROOTS} )) || typeset -ga CLAUDE_WORK_ROOTS=()

(( ${+CLAUDE_PERSONAL_ROOTS} )) || typeset -ga CLAUDE_PERSONAL_ROOTS=(
  "$HOME/.dotfiles"
)

zmodload -F zsh/stat b:zstat 2>/dev/null

_claude-under() {
  local here=${PWD:A} root
  for root in "${(@P)1}"; do
    root=${root:A}
    if [[ -n $root && ( $here == $root || $here == $root/* ) ]]; then
      typeset -g _claude_root=$root
      return 0
    fi
  done
  return 1
}

_claude-classify() {
  typeset -g REPLY= _claude_why=
  case $CLAUDE_ACCOUNT in
    work|personal)
      REPLY=$CLAUDE_ACCOUNT; _claude_why="CLAUDE_ACCOUNT=$CLAUDE_ACCOUNT"; return 0 ;;
  esac
  if _claude-under CLAUDE_WORK_ROOTS; then
    REPLY=work; _claude_why="under work root ${_claude_root/#$HOME/~}"; return 0
  fi
  if _claude-under CLAUDE_PERSONAL_ROOTS; then
    REPLY=personal; _claude_why="under personal root ${_claude_root/#$HOME/~}"; return 0
  fi
  local url
  url=$(command git config --get remote.origin.url 2>/dev/null)
  case $url in
    *github.com-work:*)
      REPLY=work; _claude_why="origin is github.com-work"; return 0 ;;
    *github.com-personal:*)
      REPLY=personal; _claude_why="origin is github.com-personal"; return 0 ;;
  esac
  _claude_why="no root matched; origin ${url:-<none>} carries no identity alias"
  return 1
}

_claude-email() {
  [[ -r $1 ]] || { print -r -- "not logged in"; return }
  if (( $+commands[jq] )); then
    command jq -r '.oauthAccount.emailAddress // "not logged in"' "$1" 2>/dev/null
  else
    command sed -n 's/.*"emailAddress"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}

_claude-plan() {
  [[ -r $1 ]] || { print -r -- "-"; return }
  if (( $+commands[jq] )); then
    command jq -r '.claudeAiOauth.subscriptionType // "-"' "$1" 2>/dev/null
  else
    command sed -n 's/.*"subscriptionType"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}

_claude-org() {
  [[ -r $1 ]] || return 0
  if (( $+commands[jq] )); then
    command jq -r '.oauthAccount.organizationName // ""' "$1" 2>/dev/null
  else
    command sed -n 's/.*"organizationName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}

typeset -gA _claude_acct_cache

_claude-account() {
  local side=$1 state cred key= packed rest; local -a st
  if [[ $side == work ]]; then
    state=$HOME/.claude.json;                       cred=$HOME/.claude/.credentials.json
    typeset -g _claude_cfg="~/.claude"
  else
    state=$CLAUDE_PERSONAL_CONFIG_DIR/.claude.json; cred=$CLAUDE_PERSONAL_CONFIG_DIR/.credentials.json
    typeset -g _claude_cfg="${CLAUDE_PERSONAL_CONFIG_DIR/#$HOME/~}"
  fi
  if (( $+builtins[zstat] )); then
    zstat -A st +mtime "$state" "$cred" 2>/dev/null
    key="$side:${st[1]}:${st[2]}"
    packed=$_claude_acct_cache[$key]
  fi
  if [[ -z $packed ]]; then
    packed="$(_claude-email "$state")"$'\t'"$(_claude-plan "$cred")"$'\t'"$(_claude-org "$state")"
    [[ -n $key ]] && _claude_acct_cache[$key]=$packed
  fi
  typeset -g _claude_email=${packed%%$'\t'*}
  rest=${packed#*$'\t'}
  typeset -g _claude_plan=${rest%%$'\t'*}
  typeset -g _claude_org=${rest#*$'\t'}
  [[ $_claude_org == *"'s Organization" ]] && _claude_org=
  return 0
}

_claude-confirm-cross() {
  local picked=$1 default=$2 ans who
  _claude-account $picked
  who=$_claude_email
  [[ -n $_claude_org ]] && who="$who - $_claude_org"
  [[ -n $_claude_plan && $_claude_plan != - ]] && who="$who, $_claude_plan"
  print -ru2 --
  print -ru2 -- "  ${PWD/#$HOME/~} is $default, but you picked $picked"
  print -ru2 -- "  ($who)"
  print -nu2 -- "  continue? [y/N] "
  read -k 1 ans
  print -u2
  [[ $ans == [yY] ]]
}

_claude-select() {
  local default= why order line pick chosen= mark
  _claude-classify && default=$REPLY
  why=$_claude_why

  case $default in
    work) order=(work personal) ;;
    *)    order=(personal work) ;;
  esac

  local -a rows
  for line in $order; do
    _claude-account $line
    if [[ $line == $default ]];  then mark='   <- this directory'
    elif [[ -n $default ]];      then mark='   !! crosses context'
    else                              mark=''
    fi
    rows+=("$(printf '%-9s %-26s %-5s %-20s%s' \
      "$line" "$_claude_email" "$_claude_plan" "$_claude_cfg" "$mark")")
  done

  if (( $+commands[fzf] )); then
    pick=$(print -rl -- "${rows[@]}" | command fzf \
      --height=7 --reverse --no-multi --no-sort --no-info \
      --prompt='account > ' \
      --header="${PWD/#$HOME/~}  --  ${why}") || return 1
    [[ -n $pick ]] || return 1
    chosen=${pick%% *}
  else
    print -ru2 -- "${PWD/#$HOME/~}  --  ${why}"
    for line in "${rows[@]}"; do print -ru2 -- "  [${line[1]}] $line"; done
    print -ru2 -- "  [q] cancel"
    local key prompt="choose > "
    [[ -n $default ]] && prompt="choose [${default[1]}] > "
    while [[ -z $chosen ]]; do
      print -nu2 -- "$prompt"
      read -k 1 key || return 1
      print -u2
      case $key in
        p|P) chosen=personal ;;
        w|W) chosen=work ;;
        $'\n'|$'\r') [[ -n $default ]] || return 1; chosen=$default ;;
        q|Q|$'\e')   return 1 ;;
      esac
    done
  fi

  if [[ -n $default && $chosen != $default ]]; then
    _claude-confirm-cross $chosen $default || return 1
  fi
  print -r -- $chosen
}

_claude-term-mark() {
  local side=$1 bg
  [[ -t 2 ]] || return 0
  case $side in
    work)     bg=${CLAUDE_WORK_BG:-#231519} ;;
    personal) bg=${CLAUDE_PERSONAL_BG:-#121e1c} ;;
    *)        return 0 ;;
  esac
  print -n -- "\e]11;${bg}\a" >&2
  [[ $TERM_PROGRAM == WezTerm ]] &&
    print -n -- "\e]1337;SetUserVar=claude_account=$(print -n -- $side | base64 | tr -d '\n')\a" >&2
  return 0
}

_claude-term-unmark() {
  [[ -t 2 ]] || return 0
  print -n -- "\e]111\a" >&2
  [[ $TERM_PROGRAM == WezTerm ]] && print -n -- "\e]1337;SetUserVar=claude_account=\a" >&2
  return 0
}

_claude-run-work() {
  local rc
  _claude-term-mark work
  { command env -u CLAUDE_CONFIG_DIR claude "$@"; rc=$? } always { _claude-term-unmark }
  return $rc
}

_claude-run-personal() {
  local rc
  _claude-term-mark personal
  { CLAUDE_CONFIG_DIR="$CLAUDE_PERSONAL_CONFIG_DIR" command claude "$@"; rc=$? } always { _claude-term-unmark }
  return $rc
}

_claude-refuse() {
  print -ru2 -- "$1: ${PWD/#$HOME/~} is $3 territory."
  print -ru2 -- "  use instead:  $2"
  print -ru2 -- "  or override:  CLAUDE_SKIP_CONTEXT_GUARD=1 $1"
  return 1
}

claude() {
  local side
  if [[ $# -eq 1 && $1 == (-v|--version|-h|--help) ]]; then
    command claude "$@"
    return
  fi
  if [[ $CLAUDE_ACCOUNT == (work|personal) ]]; then
    _claude-run-$CLAUDE_ACCOUNT "$@"
    return
  fi
  if [[ ! -t 0 || ! -t 2 ]]; then
    if _claude-classify; then
      _claude-run-$REPLY "$@"
      return
    fi
    print -ru2 -- "claude: ${PWD/#$HOME/~} is unclassified and there is no terminal to ask on."
    print -ru2 -- "  use: claude-work | claude-personal | CLAUDE_ACCOUNT=... claude"
    return 1
  fi
  side=$(_claude-select) || { print -ru2 -- "claude: cancelled."; return 130 }
  _claude-run-$side "$@"
}

claude-work() {
  if [[ -z $CLAUDE_SKIP_CONTEXT_GUARD ]] && _claude-classify && [[ $REPLY == personal ]]; then
    _claude-refuse claude-work claude-personal personal
    return 1
  fi
  _claude-run-work "$@"
}

claude-personal() {
  if [[ -z $CLAUDE_SKIP_CONTEXT_GUARD ]] && _claude-classify && [[ $REPLY == work ]]; then
    _claude-refuse claude-personal claude-work work
    return 1
  fi
  _claude-run-personal "$@"
}

claude-which() {
  local side
  if _claude-classify; then side=$REPLY; else side="none (picker opens with no default)"; fi
  print -r -- "  directory  ${PWD/#$HOME/~}"
  print -r -- "  preselect  $side"
  print -r -- "  because    $_claude_why"
  case $side in
    work|personal)
      _claude-account $side
      print -r -- "  account    $_claude_email ($_claude_plan)"
      [[ -n $_claude_org ]] && print -r -- "  org        $_claude_org"
      print -r -- "  config     $_claude_cfg" ;;
  esac
}

if (( $+functions[compdef] )) && (( ${+_comps[claude]} )); then
  compdef claude-work=claude
  compdef claude-personal=claude
  compdef claude-which=claude
fi
