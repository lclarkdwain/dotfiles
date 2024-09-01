fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions/src )
source $XDG_CONFIG_HOME/zsh/.zsh_aliases
export PATH="$HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-bench:$PATH"
fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-getantidote-SLASH-use-omz )
source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-getantidote-SLASH-use-omz/antidote-use-omz.plugin.zsh
source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-getantidote-SLASH-use-omz/use-omz.plugin.zsh
fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/nvm )
source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/nvm/nvm.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
zsh-defer source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
