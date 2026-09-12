# Monitoring

System health checking. Live resource monitoring now lives in caelestia's
dashboard (`SUPER K`), which covers CPU, GPU, temperatures, memory, storage and
network — see [caelestia.md](caelestia.md).

## The health check

`~/.local/bin/sysdiag` — a report by default, `--json` for machine use,
`--notify` for the timer.

```sh
sysdiag                  # report; exit 0 ok, 1 warn, 2 crit
sysdiag --json | jq .
sysdiag --save-baseline  # record current boot time as the reference
```

Bound to `SUPER SHIFT Y`, which opens the report in a floating terminal.

Checks: session roles filled · failed units · `graphical-session.target` active
· journal errors · coredumps · boot time vs baseline · NVIDIA module built for
every installed kernel · disk space · orphans/`.pacnew`/foreign packages ·
memory and swap.

### Three design choices worth keeping

- **Recent, not cumulative.** Journal errors and crashes are judged on a
  15-minute window with the boot total as context. A rough startup would
  otherwise flag red all day.
- **Never reaches into the boot burst.** That window is clamped so it never
  starts earlier than 90s after boot, or every fresh boot would flag amber on
  its own startup noise.
- **Roles, not process names.** The session check asks "is there a bar" and "is
  anything owning the notification bus", not "is waybar running". Swapping the
  shell is a choice, not a fault — this is what let the check survive the move
  from waybar/swaync to caelestia unchanged.

### Silence on green

`sysdiag.timer` runs 90s after login and notifies **only when something is
wrong**. A check that greets you every morning gets muted within a week.

### The NVIDIA check

The one that earns its place: if a kernel update lands without DKMS rebuilding
the NVIDIA module, the next boot comes up with no display. `sysdiag` flags that
while it is still fixable.

### What it has actually caught

- 13 coredumps per boot from `hyprpolkitagent`, `awww-daemon` and
  `xdg-desktop-portal-hyprland`, all traced to an inactive
  `graphical-session.target`. Zero after the fix.
- An Xbox controller re-enumerating ~50 times in 15 minutes through a Genesys
  USB hub, with the kernel logging `disabled by hub (EMI?)`. Invisible
  otherwise.

## Session units

`hyprland-session.target` exists because nothing else starts
`graphical-session.target`. Without it, every unit ordered on that target —
`xdg-desktop-portal-hyprland`, `hyprpolkitagent` — either never ran or failed at
boot and stayed failed. `system_startup.lua` starts it in the same command that
imports the environment, chained with `&&`, because `exec_once` backgrounds each
entry and the target would otherwise race the import.

## CPU wattage

`/sys/class/powercap/.../energy_uj` is root-only by default as a mitigation for
CVE-2020-8694. `scripts/install-scripts/arch/install-rapl-access.sh` installs a
udev rule making the counters `0440 root:wheel`.

Nothing reads it now that the sysmon panel is gone — caelestia's dashboard does
not show wattage. Kept because the rule is harmless and the reasoning is worth
preserving if a power readout is ever wanted again.
