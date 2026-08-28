#if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
#       Hyprland
#fi

# Browser
if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER="${BROWSER:-open}"
fi

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

path=(
  $HOME/{,s}bin(N)
  $HOME/{.local,.cargo,.opencode}/{,s}bin(N)
  $HOME/.local/opt/rtk(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  # Go binaries
  /usr/local/go/bin(N)
  $HOME/go/bin(N)
  # Mobile Development
  $HOME/Android/Sdk/emulator(N)
  $HOME/Android/Sdk/platform-tools(N)
  $HOME/Android/Sdk/cmdline-tools/latest/bin(N)
  $HOME/development/flutter/bin(N)
  $path
)
