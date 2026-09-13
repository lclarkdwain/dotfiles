# Caelestia terminal integration, ported from caelestia-dots' config.fish (these
# dots use zsh, so the fish config is not pulled).

# Apply the current colour scheme. The CLI pushes it to terminals already open on
# every scheme change; this covers terminals opened afterwards.
cat "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/sequences.txt" 2>/dev/null

# Mark each prompt start (OSC 133;A) so foot can jump between prompts.
_caelestia_mark_prompt() { printf '\e]133;A\e\\' }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _caelestia_mark_prompt
