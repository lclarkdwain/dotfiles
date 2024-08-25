# General

alias reload="source ~/.bashrc"
alias _='sudo'

alias c='clear'
alias cls='clear'

alias rr="rm -rf"

# Enable Color Support

if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  # alias dir='dir --color=auto'
  # alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# Directory Listing & Traversal

alias la='ls -AF' # Compact view, show hidden
alias ll='ls -al'
alias l='ls -a'
alias l1='ls -1'
alias lf='ls -F'

alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"               # Go to previous dir with -
alias cd.='cd $(readlink -f .)' # Go to real dir (i.e. if current dir is linked)

# Directory

alias md='mkdir -p'
alias rd='rmdir'

# Shell History

alias h='history'

# Network

alias ip="curl -s ipinfo.io | jq -r '.ip'"
alias ipl="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"

# Miscellaneous

alias quit="exit"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Editor

alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# Tmux

alias txl='tmux ls'
alias txn='tmux new -s'
alias txa='tmux a -t'
alias txad='tmux a -d -t'
alias txk='tmux kill-session -t'

# Systemctl

case $OSTYPE in
linux*)
  # Improve aliases by bringing the common root `sc|scd` + `sre` for action + `u` for user
  alias sc='systemctl'
  alias scu='systemctl --user'
  alias scdr='systemctl daemon-reload'
  alias scdru='systemctl --user daemon-reload'
  alias scr='systemctl restart'
  alias scru='systemctl --user restart'
  alias sce='systemctl stop'
  alias sceu='systemctl --user stop'
  alias scs='systemctl start'
  alias scsu='systemctl --user start'
  # Keeping previous aliases for a non-breaking change.
  alias scue='sceu'
  alias scus='scsu'
  alias scur='scdru'
  ;;
esac

# NPM

alias ni='npm install'
alias nis='npm install --save'
alias nid='npm install --save-dev'
alias nit='npm install-test'
alias nits='npm install-test --save'
alias nitd='npm install-test --save-dev'
alias nu='npm uninstall'
alias nus='npm uninstall --save'
alias nusd='npm uninstall --save-dev'
alias np='npm publish'
alias nup='npm unpublish'
alias nlk='npm link'
alias nod='npm outdated'
alias nrb='npm rebuild'
alias nud='npm update'
alias nr='npm run'
alias nls='npm list --depth=0 2>/dev/null'
alias nlsg='npm list -g --depth=0 2>/dev/null'
alias nt='npm test'

# NPX

alias nx='npx'
alias nxplease='npx $(fc -ln -1)'
alias nxn='npx --no-install '
alias nxp='npx -p '
alias nxnp='npx --no-install -p '
alias nxq='npx -q '
alias nxnq='npx --no-install -q '
alias nxqp='npx -q -p '
alias nxnqp='npx --no-install -q -p '
alias nxni='npx --no-install --ignore-existing '
alias nxip='npx --ignore-existing -p '
alias nxnip='npx --no-install --ignore-existing -p '
alias nxqi='npx -q --ignore-existing '
alias nxniq='npx --no-install --ignore-existing -q '
alias nxiqp='npx --ignore-existing -q -p '
alias nxniqp='npx --no-install --ignore-existing -q -p '
