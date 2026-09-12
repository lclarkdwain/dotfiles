# Monitoring

A desktop telemetry panel and a post-boot health check. Both are additions —
waybar, hypr decorations and animations are untouched.

Tuned for: Ryzen 5 5600X · RTX 2060 · ASUS board with EC sensors · single
1080p 75 Hz monitor · btrfs. Last reviewed 2026-09-12.

## The panel

A Quickshell config (`qs -c sysmon`) drawing a column of cards down the right
edge: health, CPU, GPU, power, memory, I/O.

It is deliberately impossible for it to get in the way:

| property | value | effect |
| --- | --- | --- |
| layer | `background` | sits above the wallpaper, below every window |
| `exclusionMode` | `Ignore` | never reserves space, never moves waybar |
| `keyboardFocus` | `None` | cannot take focus |

On top of that it fades out whenever the focused workspace has a window on it,
and hides outright for fullscreen. **Sampling stops entirely while hidden** —
no timers, no `nvidia-smi` — so it costs nothing during a game.

| key | action |
| --- | --- |
| `SUPER SHIFT D` | cycle auto → pinned on → pinned off |
| `SUPER SHIFT Y` | full health report in a floating terminal |

IPC, for scripts: `qs -c sysmon ipc call panel {toggle,pin,unpin,auto,status}`.

> `show` and `hide` are not available as IPC names — `qs ipc call panel show`
> is swallowed by the `ipc show` subcommand. Hence `pin`/`unpin`.

### Where the numbers come from

`~/.local/bin/sysmon-sample` emits one JSON line per interval and is the only
thing that touches `/proc` and `/sys`. Run it directly to debug:

```sh
sysmon-sample --once | jq .
sysmon-sample -i 1          # stream
```

Every sensor is resolved **by hwmon name and label**, never by index —
`hwmonN` numbering is not stable across boots, and hardcoding it would
silently report NVMe temperatures as VRM temperatures after some future
reboot.

GPU figures come from one long-lived `nvidia-smi dmon` stream rather than a
process spawned per tick.

### Power is an estimate

There is no battery and no smart plug, so total system draw **cannot** be
measured. The panel shows real CPU package and GPU board figures plus a flat
`baselineWatts` for board, drives and fans, and labels the total `est.`. The
badge reads `partial` whenever a real figure is missing.

CPU wattage needs `/sys/class/powercap/.../energy_uj`, which is root-only by
default as a mitigation for CVE-2020-8694. To enable it:

```sh
scripts/install-scripts/arch/install-rapl-access.sh
```

That installs a udev rule making the counters `0440 root:wheel`. Skip it and
CPU watts read `n/a`; nothing else changes.

### Theming

Wallust writes `~/.config/quickshell/sysmon/wallust/colors.json` from
`.config/wallust/templates/colors-quickshell.json`, alongside the waybar, rofi
and hypr templates. The panel watches that file, so a wallpaper change
re-themes it live with no restart.

Background, foreground and accent follow the wallpaper. **Status colours
(ok/warn/crit) deliberately do not** — the palette is wallpaper-derived, so
`color1` is only sometimes red, and a critical temperature has to read as
critical every time.

## The health check

`~/.local/bin/sysdiag` — a report by default, `--json` for the panel,
`--notify` for the timer.

```sh
sysdiag                  # report; exit 0 ok, 1 warn, 2 crit
sysdiag --json | jq .
sysdiag --save-baseline  # record current boot time as the reference
```

Checks: session processes alive · failed units · `graphical-session.target`
active · journal errors · coredumps · boot time vs baseline · NVIDIA module
built for every installed kernel · disk space · orphans/`.pacnew`/foreign
packages · memory and swap.

Two design choices worth keeping:

- **Recent, not cumulative.** Journal errors and crashes are judged on a
  15-minute window, with the boot total as context. A rough startup would
  otherwise flag red all day.
- **Silence on green.** `sysdiag.timer` runs 90s after login and notifies only
  when something is wrong. A check that greets you every morning gets muted
  within a week.

### The NVIDIA check

The one that earns its place: if a kernel update lands without DKMS rebuilding
the NVIDIA module, the next boot comes up with no display. `sysdiag` flags that
while you can still fix it.

## Session units

`hyprland-session.target` exists because nothing else starts
`graphical-session.target`. Without it, every unit ordered on that target —
`swaync`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent` — either never ran
or failed at boot and stayed failed. `system_startup.lua` starts it in the same
command that imports the environment, chained with `&&`, because `exec_once`
backgrounds each entry and the target would otherwise race the import.

swaync is started by its unit, not `exec_once`; two copies fight over the
`org.freedesktop.Notifications` bus name and the loser exits 1.
