# Google Cloud CLI completion: AUR package, then Google's apt/Homebrew layouts
for _gc in \
  /opt/google-cloud-cli/completion.zsh.inc \
  /usr/share/google-cloud-sdk/completion.zsh.inc \
  /usr/lib/google-cloud-sdk/completion.zsh.inc \
  ${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc; do
  if [[ -r $_gc ]]; then
    source "$_gc"
    break
  fi
done
unset _gc
