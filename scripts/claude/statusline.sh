#!/usr/bin/env bash
# Claude Code status line. Payload schema: https://code.claude.com/docs/en/statusline
#
#   ● PERSONAL  me@example.com · dotfiles  main* ↑1 · PR #12 approved · ⎇ wt · my-session
#   Opus high · ▰▰▱▱▱▱▱▱▱▱ 18% 180k/1M · 5h 23% ↻2h10m · 7d 41% ↻3d · cache 42m · $1.23 · 12m · +156 −23
set -uo pipefail

side=${1:-}
payload=$(cat)

# No argument: infer the account from the config dir the claude() wrapper in
# .config/zsh/.zshrc.d/claude.zsh launched with. Work runs with it unset.
if [[ -z $side ]]; then
  if [[ -z ${CLAUDE_CONFIG_DIR:-} ]]; then
    side=work
  elif [[ $CLAUDE_CONFIG_DIR -ef ${CLAUDE_PERSONAL_CONFIG_DIR:-$HOME/.claude-personal} ]]; then
    side=personal
  else
    side=unknown
  fi
fi

case $side in
  work)     state=$HOME/.claude.json
            label=WORK      ; accent=$'\033[38;5;209m' ;;
  personal) state=${CLAUDE_PERSONAL_CONFIG_DIR:-$HOME/.claude-personal}/.claude.json
            label=PERSONAL  ; accent=$'\033[38;5;79m'  ;;
  *)        state=; label=${side^^}; accent=$'\033[38;5;244m' ;;
esac

dim=$'\033[38;5;244m'; reset=$'\033[0m'
green=$'\033[38;5;114m'; yellow=$'\033[38;5;221m'; red=$'\033[38;5;203m'
blue=$'\033[38;5;111m'; magenta=$'\033[38;5;176m'
sep="${dim} · ${reset}"

command -v jq >/dev/null 2>&1 && _jq=1 || _jq=

email=
if [[ -n $state && -r $state ]]; then
  if [[ -n $_jq ]]; then
    email=$(jq -r '.oauthAccount.emailAddress // empty' "$state" 2>/dev/null)
  else
    email=$(sed -n 's/.*"emailAddress"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$state" | head -1)
  fi
fi

line1="${accent}● ${label}${reset}"
[[ -n $email ]] && line1+="${dim}  ${email}${reset}"

# Without jq there is nothing to parse the payload with; show identity only.
if [[ -z $_jq ]]; then
  printf '%s' "$line1"
  exit 0
fi

# One jq pass, emitted as shell assignments. Missing fields become ''; the
# defaults cover a payload jq cannot parse.
cwd= model= effort= fast= session= vim= agent= wt= pr_num= pr_url= pr_state=
ctx_pct= ctx_used= ctx_size= rl5_pct= rl5_at= rl7_pct= rl7_at=
cache_on= cache_warm= cache_exp= cost=0 dur_ms= added= removed=
eval "$(printf '%s' "$payload" | jq -r '
  def s: if . == null then "" else tostring end;
  def i: if . == null then "" else floor | tostring end;
  {
    cwd:        (.workspace.current_dir // .cwd),
    model:      .model.display_name,
    effort:     .effort.level,
    fast:       (if .fast_mode then "1" else null end),
    session:    .session_name,
    vim:        .vim.mode,
    agent:      .agent.name,
    wt:         (.worktree.name // .workspace.git_worktree),
    pr_num:     .pr.number,
    pr_url:     .pr.url,
    pr_state:   .pr.review_state,
    ctx_pct:    (.context_window.used_percentage | i),
    ctx_used:   (.context_window.total_input_tokens | i),
    ctx_size:   (.context_window.context_window_size | i),
    rl5_pct:    (.rate_limits.five_hour.used_percentage | i),
    rl5_at:     (.rate_limits.five_hour.resets_at | i),
    rl7_pct:    (.rate_limits.seven_day.used_percentage | i),
    rl7_at:     (.rate_limits.seven_day.resets_at | i),
    cache_on:   (if .prompt_cache.caching_observed then "1" else null end),
    cache_warm: (if .prompt_cache.warm then "1" else null end),
    cache_exp:  (.prompt_cache.expires_at | i),
    cost:       (.cost.total_cost_usd // 0 | . * 100 | floor | tostring),
    dur_ms:     (.cost.total_duration_ms | i),
    added:      (.cost.total_lines_added | i),
    removed:    (.cost.total_lines_removed | i)
  } | to_entries[] | "\(.key)=\(.value | s | @sh)"
' 2>/dev/null)"

now=$(date +%s)

# 7260 -> 2h1m, 90000 -> 1d1h
fmt_dur() {
  local t=${1:-0}
  (( t < 0 )) && t=0
  if   (( t >= 86400 )); then printf '%dd%dh' $((t/86400)) $((t%86400/3600))
  elif (( t >= 3600  )); then printf '%dh%dm' $((t/3600))  $((t%3600/60))
  elif (( t >= 60    )); then printf '%dm'    $((t/60))
  else                        printf '%ds'    "$t"
  fi
}

# 180000 -> 180k, 1000000 -> 1M, 1250000 -> 1.2M
fmt_tok() {
  local n=${1:-0}
  if   (( n >= 1000000 )); then
    (( n % 1000000 < 100000 )) && printf '%dM' $((n/1000000)) \
                               || printf '%d.%dM' $((n/1000000)) $((n%1000000/100000))
  elif (( n >= 1000 )); then printf '%dk' $((n/1000))
  else                       printf '%d'  "$n"
  fi
}

# Colour by how close a percentage is to its limit.
heat() {
  if   (( $1 >= 80 )); then printf '%s' "$red"
  elif (( $1 >= 50 )); then printf '%s' "$yellow"
  else                      printf '%s' "$green"
  fi
}

# OSC 8 hyperlink; terminals without support print the text only.
link() { printf '\033]8;;%s\a%s\033]8;;\a' "$1" "$2"; }

# --- git ------------------------------------------------------------------
# Cached briefly per directory: the status line re-runs on every message and
# `git status` is not free in large repos.
git_seg=
if [[ -n $cwd && -d $cwd ]]; then
  cache_dir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/claude-statusline
  cache_file=$cache_dir/$(printf '%s' "$cwd" | cksum | cut -d' ' -f1)
  if [[ -f $cache_file ]] && (( now - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) < 5 )); then
    git_seg=$(<"$cache_file")
  else
    if porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
      branch= oid= ahead=0 behind=0 dirty=
      while IFS= read -r l; do
        case $l in
          '# branch.head '*) branch=${l#'# branch.head '} ;;
          '# branch.oid '*)  oid=${l#'# branch.oid '} ;;
          '# branch.ab '*)   read -r _ _ a b <<<"$l"; ahead=${a#+}; behind=${b#-} ;;
          '#'*) ;;
          *) dirty='*' ;;
        esac
      done <<<"$porcelain"
      [[ $branch == '(detached)' ]] && branch=${oid:0:7}
      git_seg="${magenta} ${branch}${dirty}${reset}"
      (( ahead  > 0 )) && git_seg+="${dim} ↑${ahead}${reset}"
      (( behind > 0 )) && git_seg+="${dim} ↓${behind}${reset}"
    fi
    mkdir -p "$cache_dir" 2>/dev/null && printf '%s' "$git_seg" >"$cache_file" 2>/dev/null
  fi
fi

# --- line 1: where am I ---------------------------------------------------
[[ -n $cwd ]] && line1+="${dim} · ${cwd##*/}${reset}"
[[ -n $git_seg ]] && line1+=" ${git_seg}"
if [[ -n $pr_num ]]; then
  case $pr_state in
    approved)          c=$green  ;;
    changes_requested) c=$red    ;;
    *)                 c=$yellow ;;
  esac
  pr="PR #${pr_num}"
  [[ -n $pr_url ]] && pr=$(link "$pr_url" "$pr")
  line1+="${sep}${c}${pr}${reset}"
  [[ -n $pr_state ]] && line1+="${dim} ${pr_state//_/ }${reset}"
fi
[[ -n $wt      ]] && line1+="${sep}${blue}⎇ ${wt}${reset}"
[[ -n $agent   ]] && line1+="${sep}${blue}@${agent}${reset}"
[[ -n $session ]] && line1+="${sep}${dim}${session}${reset}"

# --- line 2: what is it costing -------------------------------------------
line2=
[[ -n $model  ]] && line2+="${model}"
[[ -n $effort ]] && line2+="${dim} ${effort}${reset}"
[[ -n $fast   ]] && line2+="${yellow} ⚡${reset}"
[[ -n $vim    ]] && line2+="${sep}${blue}${vim}${reset}"

if [[ -n $ctx_pct ]]; then
  c=$(heat "$ctx_pct"); filled=$(( (ctx_pct + 5) / 10 )); (( filled > 10 )) && filled=10
  bar=
  for ((k = 0; k < 10; k++)); do (( k < filled )) && bar+='▰' || bar+='▱'; done
  line2+="${sep}${c}${bar} ${ctx_pct}%${reset}"
  [[ -n $ctx_size ]] && line2+="${dim} $(fmt_tok "$ctx_used")/$(fmt_tok "$ctx_size")${reset}"
fi

rate() {  # label pct resets_at
  [[ -n $2 ]] || return 0
  local out="${sep}${dim}$1 ${reset}$(heat "$2")$2%${reset}"
  [[ -n $3 ]] && out+="${dim} ↻$(fmt_dur $(( $3 - now )))${reset}"
  printf '%s' "$out"
}
line2+=$(rate 5h "$rl5_pct" "$rl5_at")
line2+=$(rate 7d "$rl7_pct" "$rl7_at")

# A cold cache means the next message re-reads the whole context at full price.
if [[ -n $cache_on ]]; then
  if [[ -n $cache_warm && -n $cache_exp ]]; then
    line2+="${sep}${dim}cache ${reset}${green}$(fmt_dur $(( cache_exp - now )))${reset}"
  else
    line2+="${sep}${dim}cache ${reset}${yellow}cold${reset}"
  fi
fi

(( ${cost:-0} > 0 )) && line2+="${sep}${dim}\$$(( cost / 100 )).$(printf '%02d' $(( cost % 100 )))${reset}"
[[ -n $dur_ms ]] && (( dur_ms > 0 )) && line2+="${sep}${dim}$(fmt_dur $(( dur_ms / 1000 )))${reset}"
if (( ${added:-0} + ${removed:-0} > 0 )); then
  line2+="${sep}${green}+${added:-0}${reset} ${red}−${removed:-0}${reset}"
fi

printf '%s' "$line1"
[[ -n $line2 ]] && printf '\n%s' "${line2#"$sep"}"
