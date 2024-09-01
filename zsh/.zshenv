#!/usr/bin/env zsh

# Dotfiles
export DOTFILES="$HOME/.dotfiles"

# XDG Base Directory Specification (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

# Starship
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# Man
export MANPAGER='nvim --cmd ":lua vim.g.noplugins=1" +Man!'
export MANWIDTH=999

# Rust
. "$HOME/.cargo/env"
