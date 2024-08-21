# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
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

for DOTFILE in "$DOTFILES_DIR"/bash/.bash_{function,function_*,path,env,aliases,prompt,completion}; do
  . "$DOTFILE"
  if [[ -f "${DOTFILE}.local" ]]; then
    . "${DOTFILE}.local"
  fi
done

. "$HOME/.cargo/env"

# Fin

export DOTFILES_DIR

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

source ~/.local/share/blesh/ble.sh

cdnvm() {
  command cd "$@" || return $?
  nvm_path="$(nvm_find_up .nvmrc | command tr -d '\n')"

  # If there are no .nvmrc file, use the default nvm version
  if [[ ! $nvm_path = *[^[:space:]]* ]]; then

    declare default_version
    default_version="$(nvm version default)"

    # If there is no default version, set it to `node`
    # This will use the latest version on your machine
    if [ $default_version = 'N/A' ]; then
      nvm alias default node
      default_version=$(nvm version default)
    fi

    # If the current version is not the default version, set it to use the default version
    if [ "$(nvm current)" != "${default_version}" ]; then
      nvm use default
    fi
  elif [[ -s "${nvm_path}/.nvmrc" && -r "${nvm_path}/.nvmrc" ]]; then
    declare nvm_version
    nvm_version=$(<"${nvm_path}"/.nvmrc)

    declare locally_resolved_nvm_version
    # `nvm ls` will check all locally-available versions
    # If there are multiple matching versions, take the latest one
    # Remove the `->` and `*` characters and spaces
    # `locally_resolved_nvm_version` will be `N/A` if no local versions are found
    locally_resolved_nvm_version=$(nvm ls --no-colors "${nvm_version}" | command tail -1 | command tr -d '\->*' | command tr -d '[:space:]')

    # If it is not already installed, install it
    # `nvm install` will implicitly use the newly-installed version
    if [ "${locally_resolved_nvm_version}" = 'N/A' ]; then
      nvm install "${nvm_version}"
    elif [ "$(nvm current)" != "${locally_resolved_nvm_version}" ]; then
      nvm use "${nvm_version}"
    fi
  fi
}

alias cd='cdnvm'
cdnvm "$PWD" || exit
