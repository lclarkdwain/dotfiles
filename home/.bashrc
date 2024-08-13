# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Make utilities available

if [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

PATH="$DOTFILES_DIR/.local/bin:$PATH"

# Loader

for DOTFILE in "$DOTFILES_DIR"/dots/.bash_{function,function_*,path,env,aliases,prompt,completion}; do
  . "$DOTFILE"
  if [[ -f "${DOTFILE}.local" ]]; then
    . "${DOTFILE}.local"
  fi
done

. "$HOME/.cargo/env"

# Fin

export DOTFILES_DIR

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
