#!/bin/bash

# Configures granted (https://granted.dev) for a Hyprland/Wayland session with no
# desktop environment. Applies settings to ~/.config/granted/config rather than
# tracking that file as a dotfile: granted writes AWS credentials into that
# directory whenever its secret-service backend is unavailable, and a directory
# that is both a live credential store and a tracked repo path is one `git add -f`
# or one edited ignore rule away from publishing them.
#
# Four settings, all of which granted gets wrong by default on such a box:
#
#  1. CustomSSOBrowserPath. Left empty, pkg/idclogin/run.go falls through to
#     browser.OpenURL, which runs `xdg-open <url>` via cmd.Run() -- it *waits* for
#     xdg-open to exit. xdg-open's detectDE has no case for
#     XDG_CURRENT_DESKTOP=Hyprland, so it uses open_generic, which execs the
#     handler in the foreground. With no browser already running, that process is
#     the browser and lives until its window closes, so `assume` hangs before it
#     ever starts polling for the SSO token -- approving in the browser does
#     nothing. Setting this takes the branch that does Start() + Process.Release().
#
#     Do NOT set this with `granted browser set-sso -b chrome`: upstream bug in
#     pkg/granted/browser.go skips computing browserPath when -b is passed, and
#     saves an empty value.
#
#  2. Keyring.Backend. granted already prefers secret-service -- its default order
#     is [secret-service kwallet keyctl pass file] -- so this is not what makes the
#     keyring work. It forbids the silent fall back to the `file` backend, whose
#     passphrase is *always* os.Getenv("CF_KEYRING_FILE_PASSWORD") (it never
#     prompts), i.e. the empty string. Pinning turns a silent downgrade into a loud
#     failure.
#
#  3. Keyring.LibSecretCollectionName. granted otherwise asks for a collection per
#     store ("granted-aws-sso-tokens" and friends). Creating a non-default
#     collection goes through a gcr prompter dialog to choose a password, and PAM
#     only auto-unlocks the *login* keyring -- so each would demand an unlock every
#     session. Pointing all stores at "login" uses the keyring PAM already opened.
#
#     Trade-off: the stores share one collection's key space. granted keys session
#     credentials and IAM credentials both by profile name, so a profile added via
#     `granted credentials add` sharing a name with an SSO profile would collide.
#     There are no IAM credentials on this box (SSO only), and a collision surfaces
#     as a decode error rather than silently.
#
#  4. Keyring.FileDir. Moves the file backend's directory out of
#     ~/.config/granted, so a fall back to it cannot write credentials next to the
#     config. 99designs/keyring resolveDir() calls ExpandTilde, so "~/" works.

set -euo pipefail

if ! source "$(dirname "$(realpath "$0")")/../../utilities.sh"; then
  echo "failed to source utilities.sh"
  exit 1
fi

if ! command -v granted &>/dev/null; then
  log INFO "granted is not installed; skipping granted configuration"
  exit 0
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/granted"
CONFIG_FILE="$CONFIG_DIR/config"

mkdir -p "$CONFIG_DIR"
[ -f "$CONFIG_FILE" ] || : >"$CONFIG_FILE"

sso_browser=""
for candidate in /usr/bin/google-chrome-stable /usr/bin/chromium /usr/bin/firefox; do
  if [ -x "$candidate" ]; then
    sso_browser="$candidate"
    break
  fi
done

if [ -z "$sso_browser" ]; then
  log WARN "no known browser binary found; leaving CustomSSOBrowserPath alone"
fi

# Only pin the backend once gnome-keyring is present to provide it. Note this pin
# is Linux-only: macOS wants "keychain", so revisit if these dotfiles grow a real
# darwin install path.
keyring_backend=""
keyring_collection=""
if command -v gnome-keyring-daemon &>/dev/null; then
  keyring_backend="secret-service"
  keyring_collection="login"
else
  log WARN "gnome-keyring is not installed; not pinning Keyring.Backend."
  log WARN "granted will fall back to its file backend with an EMPTY passphrase."
fi

# Set regardless of backend: it is exactly the fall-back case that must not write
# credentials into a directory anyone might later track.
keyring_filedir="~/.local/state/granted/keyring"

SSO_BROWSER="$sso_browser" \
  KEYRING_BACKEND="$keyring_backend" \
  KEYRING_COLLECTION="$keyring_collection" \
  KEYRING_FILEDIR="$keyring_filedir" \
  python3 - "$CONFIG_FILE" <<'PY'
import os
import re
import sys

path = sys.argv[1]
with open(path) as fh:
    text = fh.read()

browser = os.environ.get("SSO_BROWSER", "")
backend = os.environ.get("KEYRING_BACKEND", "")
collection = os.environ.get("KEYRING_COLLECTION", "")
filedir = os.environ.get("KEYRING_FILEDIR", "")


def set_flat_key(body, key, value):
    """Set a top-level key, inserting it before the first table header."""
    pattern = re.compile(rf'^{re.escape(key)}\s*=.*$', re.MULTILINE)
    line = f'{key} = "{value}"'
    if pattern.search(body):
        return pattern.sub(line, body, count=1)
    table = re.search(r'^\[', body, re.MULTILINE)
    at = table.start() if table else len(body)
    head = body[:at].rstrip("\n")
    head = f"{head}\n" if head else ""
    return f"{head}{line}\n{body[at:]}"


def set_table(body, name, entries):
    """Replace the named table wholesale, or append it, leaving others intact."""
    block = f"[{name}]\n" + "".join(f'  {k} = "{v}"\n' for k, v in entries)
    pattern = re.compile(rf'^\[{re.escape(name)}\]\n(?:(?!\[).*\n?)*', re.MULTILINE)
    if pattern.search(body):
        return pattern.sub(block, body, count=1)
    return body.rstrip("\n") + "\n\n" + block


if browser:
    text = set_flat_key(text, "CustomSSOBrowserPath", browser)

entries = []
if backend:
    entries.append(("Backend", backend))
    if collection:
        entries.append(("LibSecretCollectionName", collection))
if filedir:
    entries.append(("FileDir", filedir))
if entries:
    text = set_table(text, "Keyring", entries)

with open(path, "w") as fh:
    fh.write(text)
PY

chmod 600 "$CONFIG_FILE"

log SUCCESS "granted configured at $CONFIG_FILE"
[ -n "$sso_browser" ] && log INFO "  CustomSSOBrowserPath    = $sso_browser"
[ -n "$keyring_backend" ] && log INFO "  Keyring.Backend         = $keyring_backend"
[ -n "$keyring_collection" ] && log INFO "  LibSecretCollectionName = $keyring_collection"
log INFO "  Keyring.FileDir         = $keyring_filedir"
exit 0
