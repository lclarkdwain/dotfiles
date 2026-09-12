# Caelestia trial

Migrating from the waybar/rofi/swaync stack to [caelestia-shell][repo], a
Quickshell-based shell that provides the bar, launcher, notifications, dashboard
and lock screen as one integrated system.

[repo]: https://github.com/caelestia-dots/shell

Status: **trialling**. Installed and running; the old stack is still intact.

## Why this is a bigger change than it looks

Caelestia is not a widget you add next to waybar. `shell.qml` instantiates every
module unconditionally, modules import each other through registered QML URIs
(`import qs.services`) built by CMake, and the resource monitoring is C++
(`plugin/src/Caelestia/Services/{cpu,gpu}.cpp`). You cannot lift one module out
of it. It is adopt-the-whole-thing or don't.

It also **replaces `quickshell` with `quickshell-git`** — the two conflict, so
the stable package is removed. `qs -c overview` runs on the git build afterwards.

## Install

```sh
scripts/install-scripts/arch/install-caelestia.sh   # snapshots packages, then builds
caelestia shell -d                                  # start it
```

Rollback at any point:

```sh
scripts/install-scripts/arch/uninstall-caelestia.sh
```

That removes the caelestia packages, swaps `quickshell-git` back to `quickshell`,
and **lists** newly-orphaned packages without deleting them — a rollback should
never remove more than it has to.

### What gets installed

Six AUR builds (`caelestia-shell`, `caelestia-cli`, `quickshell-git`,
`qt6-m3shapes-git`, `ttf-rubik-vf`, `python-materialyoucolor`) plus repo
packages: `ddcutil`, `libcava`, `aubio`, `power-profiles-daemon`, `fish`,
`fuzzel`, `gpu-screen-recorder`, `dart-sass`, `qt6-imageformats`,
`ttf-material-symbols-variable`, `ttf-cascadia-code-nerd`.

Three of those are `-git` packages, so they rebuild from source on every update.

`power-profiles-daemon` is a happy accident: waybar's `power-profiles-daemon`
module has been logging errors because the daemon was never installed.

## Two collisions to resolve

### 1. Wallpaper — handled

Caelestia draws its own wallpaper, which would fight `awww-daemon`. The trial
config sets `background.enabled: false` so the existing wallpaper stack keeps
ownership.

### 2. Colour pipeline — the real decision, deliberately deferred

The system currently themes from **wallust**: one palette derived from the
wallpaper, written out to waybar, rofi, hypr, cava and ghostty. Caelestia has
its own Material You pipeline via `python-materialyoucolor`, driven by
`caelestia wallpaper`.

Running both means the wallpaper changes through the existing scripts and
caelestia's colours do not follow. During the trial that is cosmetic and
expected — **do not try to fix it yet.**

Afterwards, pick one:

- **Caelestia owns colour.** Most cohesive, which is the point of switching.
  Wallust is retired and its templates for waybar/rofi/cava stop mattering as
  those tools are retired too. Hypr and ghostty would need feeding from
  caelestia's scheme instead.
- **Wallust owns colour.** Keeps ghostty/hypr/cava consistent with the existing
  look, but caelestia would need its scheme regenerated from the wallust
  palette, which it is not designed for.

The first is the honest choice if the goal is one cohesive system.

## Config

`~/.config/caelestia/shell.json`, tracked here as `.config/caelestia/`. Partial
configs merge: every key has a default in the C++ config nodes, so only
overrides belong in the file.

Keybinds use Hyprland **D-Bus global shortcuts**, not ordinary binds. The
Hyprland side is not written yet — see `caelestia/hypr/hyprland/keybinds.lua`
upstream for the shape.

## Running the trial

The shell is started manually, so a logout returns you to waybar/swaync
automatically — the trial cannot strand you.

```sh
caelestia shell -d                      # start
pkill waybar                            # one bar, not two
systemctl --user stop swaync.service    # let caelestia own notifications
```

Back to the old stack:

```sh
pkill -f 'qs -c caelestia'
systemctl --user start swaync.service
waybar -l error &
```

### Three collisions, all resolved

| collision | resolution |
| --- | --- |
| wallpaper | `background.enabled: false`; `awww-daemon` keeps it |
| bar | stop waybar during the trial |
| notifications | only one process can own `org.freedesktop.Notifications`; stop swaync first, or caelestia's notification UI silently receives nothing |

paru installed the **`-git`** variants (`caelestia-shell-git`, `caelestia-cli-git`)
and `quickshell-git` is **0.3.1**, a version ahead of the 0.3.0 that was replaced.

## During the trial

waybar, rofi, swaync and hyprlock all stay installed and configured. Nothing is
retired until the trial succeeds.

To compare like for like, stop waybar while looking at caelestia's bar:

```sh
pkill waybar          # restore with: waybar -l error &
```

The sysmon panel is **parked, not deleted** — its `exec_once` entry and keybind
are commented out in `configs/system_startup.lua` and
`UserConfigs/user_keybinds.lua`. `.config/quickshell/sysmon` and
`.local/bin/sysmon-sample` are untouched. `sysdiag` is independent of all of
this and keeps working either way.

If caelestia does not work out, uncomment those two lines and `hyprctl reload`.
