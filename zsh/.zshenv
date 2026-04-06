#!/usr/bin/env zsh

# Dotfiles
export DOTFILES="$HOME/.dotfiles"

# XDG Base Directory Specification (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# Zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

# Starship
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# Man
export MANPAGER='nvim --cmd ":lua vim.g.noplugins=1" +Man!'
export MANWIDTH=999

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Java
# Arch Linux standardizes the active JDK path here via archlinux-java
export JAVA_HOME="/usr/lib/jvm/default"

# Android
# The default installation path for the SDK via Android Studio
export ANDROID_HOME="$HOME/Android/Sdk"

# Others
export CHROME_EXECUTABLE="/usr/bin/google-chrome-stable"

# ...
# Guard zsh syntax because this file is sourced by bash during setup script
if [ -n "$ZSH_VERSION" ]; then
  if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile"
  fi
fi
