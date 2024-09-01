#!/usr/bin/env zsh

# single character aliases - be sparing!
alias _=sudo
alias l=ls
alias g=git

# mask built-ins with better defaults
alias vi=vim

# more ways to ls
alias ls="eza -F -gh --group-directories-first --git --git-ignore --icons --color-scale all --hyperlink"
alias lh='ls -d .*'
alias lD='ls -D'
alias lc='ls -1'

alias ll='ls -l'
alias la='ll -a'

alias lA='ll --sort=acc'
alias lC='ll --sort=cr'
alias lM='ll --sort=mod'
alias lS='ll --sort=size'
alias lX='ll --sort=ext'
alias llm='lM'

alias l='la -a'
alias lsa='l'
alias lx='l -HimUuS'
alias lxa='lx -Z@'

alias lt='ls -T'
alias tree=lt

# fix common typos
alias quit='exit'
alias cd..='cd ..'

# tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# find
alias fd='find . -type d -name'
alias ff='find . -type f -name'

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

# misc
alias please=sudo
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias zdot='cd ${ZDOTDIR:-~}'
