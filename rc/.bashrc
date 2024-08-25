# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

[[ $- == *i* ]] &&
  source "$HOME/.local/share/blesh/ble.sh" --rcfile "$HOME/.blerc"

# Make utilities available

if [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

PATH="$DOTFILES_DIR/.local/bin:$PATH"

# Loader

for DOTFILE in "$DOTFILES_DIR"/.config/bash/.bash_{function,function_*,path,env,aliases,prompt,completion}; do
  . "$DOTFILE"
  if [[ -f "${DOTFILE}.local" ]]; then
    . "${DOTFILE}.local"
  fi
done

. "$HOME/.cargo/env"

# Fin

export DOTFILES_DIR

[[ ${BLE_VERSION-} ]] && ble-attach
