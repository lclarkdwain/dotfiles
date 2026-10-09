#!/bin/bash

# Game development stack: Godot, content tools, and GPU debugging.
# Opt-in from install-arch.sh; also safe to run on its own.
#
# All official repos, so install_pacman_packages rather than install_packages
# (see install-gaming.sh for why the AUR helper is avoided here).
#
# Git LFS is enabled globally, but NOT with `git lfs install`: that writes to the
# global git config, which here is the tracked .config/git/config, and its
# `required = true` breaks LFS repos on any machine that stows that config
# without git-lfs. The same filter goes into the gitignored config.local, which
# the tracked config includes. Don't run a bare `git lfs install` later either;
# inside an existing repo, `git lfs update` installs the hooks.

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

gamedev_pkgs=(
  git-lfs
  # Standard build (GDScript + GDExtension); no Mono/.NET.
  godot
  blender
  krita
  audacity
  renderdoc
  # vulkaninfo/vkcube, for checking the Vulkan stack Godot renders with.
  vulkan-tools
)

install_pacman_packages "${gamedev_pkgs[@]}"

# Rust itself comes from common/install-rust.sh, which already ships clippy and
# rustfmt; rust-analyzer is the only component the editor still needs.
if command -v rustup &>/dev/null; then
  rustup component add rust-analyzer || log WARN "Could not add {GOLD}rust-analyzer{RESET}; run {SKY_BLUE}rustup component add rust-analyzer{RESET} later."
else
  log NOTE "rustup not found; skipping {GOLD}rust-analyzer{RESET}. Run common/install-rust.sh, then re-run this script."
fi

printf "\n%.0s" {1..1}
log INFO "Verifying the game dev stack..."

missing=()
for pkg in "${gamedev_pkgs[@]}"; do
  is_package_installed "$pkg" || missing+=("$pkg")
done

if [ ${#missing[@]} -ne 0 ]; then
  log WARN "The following game dev packages did not install:"
  for pkg in "${missing[@]}"; do
    log WARNING "$pkg"
  done
else
  log OK "All game dev packages installed."
fi

git_local_config="${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local"
if is_package_installed git-lfs; then
  git config --file "$git_local_config" filter.lfs.clean "git-lfs clean -- %f"
  git config --file "$git_local_config" filter.lfs.smudge "git-lfs smudge -- %f"
  git config --file "$git_local_config" filter.lfs.process "git-lfs filter-process"
  git config --file "$git_local_config" filter.lfs.required true
  if [ "$(git config --global --includes --get filter.lfs.process)" == "git-lfs filter-process" ]; then
    log OK "Git LFS enabled globally via {GOLD}$git_local_config{RESET}."
  else
    log WARN "Wrote {GOLD}$git_local_config{RESET}, but git doesn't see it. Check the [include] in .config/git/config."
  fi
  log NOTE "In repos cloned before this, run {SKY_BLUE}git lfs update{RESET} once to install the LFS hooks."
else
  log WARN "{GOLD}git-lfs{RESET} is not installed; skipping the global LFS filter."
fi
