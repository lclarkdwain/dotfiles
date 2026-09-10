# CLAUDE.md

GNU Stow dotfiles for Arch Linux (Ubuntu / macOS partial). Deployed by symlink.

## Edits are live

`~/.config/<tool>` are symlinks into this repo. Editing a file here changes the
running system **immediately** — no build, no deploy, no staging copy. A broken
file is a broken desktop, not a failing test.

## Layout

| package    | stowed to          | notes                                     |
| ---------- | ------------------ | ----------------------------------------- |
| `zsh/`     | `$HOME`            | `.zshenv` only; rest in `.config/zsh/`    |
| `.config/` | `$XDG_CONFIG_HOME` | one symlink per subfolder                 |
| `.local/`  | `$HOME/.local`     |                                           |
| `claude/`  | `$HOME`            | `--no-folding`: real dir, symlinked files |
| `docs/`    | not stowed         | `gaming.md`: pending manual gaming steps  |

`make dry-run` previews · `make link` deploys · `make unlink` removes

## House rules

- **Work out what a file is before editing it.** Three kinds live here and look
  identical. Editing the wrong one loses the change silently.
  - *Generated* — a tool rewrites it. Edit the source, not the output. Check
    `.config/wallust/wallust.toml` for its targets; antidote owns
    `.zsh_plugins.zsh`.
  - *Vendored* — copied from an upstream project, then customised. Local changes
    are marked `LOCAL DEVIATION` / `LOCAL FIX`; grep before touching. Never run
    an upstream sync or update script — they overwrite the whole subtree.
  - *Submodule* — see `.gitmodules`. Don't edit in place.
- **Validate before finishing**: `zsh -n`, `luac -p`, `stow -n`, `make dry-run`.
  A syntax error in `.zshenv`/`.zshrc` breaks every new shell, including the one
  you would use to fix it.
- **Never replace a symlink with a regular file.** Edit through the repo path.
- **Keep it portable.** Use `$HOME` and `$XDG_CONFIG_HOME`, never absolute
  `/home/<user>` paths. Machine-specific values belong in a gitignored
  `*.local.*` file beside a tracked `.example`.
- **One tool per directory** under `.config/`, so stow links it independently.
- Prefer the smallest change that works; this is config, not a codebase.

## Dangerous commands

- **`make link` runs `rm -rf`** on any `~/.config/<folder>` that exists and is
  not a symlink. Run `make dry-run` first and read the `Removing conflicting`
  lines.
- **Bare `make` is `install link`** — it installs packages.
- **`make backup` only saves `.zshrc` and `.config/zsh`.** It is not a general
  safety net; back up anything else yourself.
- Never `make unlink` / `make uninstall` unless asked.
- Confirm before anything that changes the live system or deletes files.
- Don't commit or push unless asked.

## This repo is public

`github.com/lclarkdwain/dotfiles`. Nothing tracked here may contain employer or
client names, email addresses, hostnames, tokens, keys, or absolute
`/home/<user>` paths.

## Claude accounts

Work and personal use separate config dirs; this repo is personal territory.
`claude` opens a picker, `claude-which` reports without launching. Never write
to `~/.claude` or `~/.claude-personal` directly — the only tracked path into
them is the `claude/` stow package.
