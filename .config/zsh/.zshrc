#!/usr/bin/env zsh

# zmodload zsh/zprof
#
# setopt histignorealldups sharehistory
# setopt extended_glob

# Use vim keybindings
# bindkey -v

# History Management
# HISTSIZE=10000
# SAVEHIST=10000
# HISTFILE=~/.zsh_history

# Lazy-load (autoload) Zsh function files from a directory.
ZFUNCDIR=${ZDOTDIR:-$HOME}/.zfunctions
fpath=($ZFUNCDIR $fpath)
autoload -Uz $ZFUNCDIR/*(.:t)

# Set any zstyles you might use for configuration.
[[ ! -f ${ZDOTDIR:-$HOME}/.zstyles ]] || source ${ZDOTDIR:-$HOME}/.zstyles

# Fetch antidote if necessary. Test for the script, not the directory: in the
# dotfiles repo .antidote is a git submodule, and a clone made without
# --recursive leaves it as an empty directory. Initialise the submodule there
# rather than cloning over it; clone only outside the repo.
if [[ ! -e ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh ]]; then
  git -C ${ZDOTDIR:-$HOME} submodule update --init .antidote 2>/dev/null ||
    git clone https://github.com/mattmc3/antidote ${ZDOTDIR:-$HOME}/.antidote
fi

# Antidote
source ${ZDOTDIR}/.antidote/antidote.zsh
antidote load

# Source anything in .zshrc.d.
for _rc in ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh; do
  # Ignore tilde files.
  if [[ $_rc:t != '~'* ]]; then
    source "$_rc"
  fi
done
unset _rc

# Starship
if type starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# fastfetch -c $HOME/.config/fastfetch/config.jsonc

# opencode
export PATH="$HOME/.opencode/bin:$PATH"
