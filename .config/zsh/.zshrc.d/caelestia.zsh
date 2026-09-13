# Caelestia terminal integration (zsh port of caelestia-dots' config.fish)
cat "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/sequences.txt" 2>/dev/null

# OSC 133 prompt marks, for jumping between prompts in foot
_caelestia_mark_prompt() { printf '\e]133;A\e\\' }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _caelestia_mark_prompt
