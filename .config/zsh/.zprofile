# Browser
if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER="${BROWSER:-open}"
fi

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

# Set the list of directories that zsh searches for commands.
# path=(
#   $HOME/{,s}bin(N)
#   /opt/{homebrew,local,nvim-linux-x86_64}/{,s}bin(N)
#   /usr/local/{,s}bin(N)
#   $HOME/.local/src/tmux-3.5a/{,s}bin(N)
#   $path
# )
path=(
  $HOME/{,s}bin(N)
  $HOME/.local/{,s}bin(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)
