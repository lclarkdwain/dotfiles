#!/usr/bin/env bash
# Legacy startup hook for layout keybind initialization.
# Runtime keybind behavior is now resolved per keypress based on active workspace layout.

set -euo pipefail

scripts_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"

# Keep compatibility with existing startup entries while avoiding global rebinding.
if [[ -x "${scripts_dir}/ChangeLayout.sh" ]]; then
  # LOCAL DEVIATION from upstream: upstream passes "--quiet init", but this
  # ChangeLayout.sh reads only $1, so "--quiet" falls through to the usage
  # branch and exits 1 (silently swallowed) -- layout keybinds never initialise.
  # Pass the subcommand it actually understands.
  "${scripts_dir}/ChangeLayout.sh" init >/dev/null 2>&1 || true
fi
