# Gaming

How the Steam setup in this repo works, what is still manual, and what to try
when a game misbehaves.

Tuned for: Ryzen 5 5600X · RTX 2060 (NVIDIA open modules) · 1080p 75 Hz monitor
on HDMI · Hyprland (Lua config) · btrfs. Last reviewed 2026-09-11.

## Pending

Steps no script can do. Tick them off here when done.

- [x] **Run `scripts/install-scripts/arch/install-gaming.sh`.** Done
  2026-09-11: ntsync, memory tuning, scx_lavd, protontricks and ProtonPlus all
  verified live. Safe to re-run: installed packages and existing `/etc` files
  are skipped.
- [ ] **Confirm RAM runs at its rated speed.** Check once. Zen 3 performance
  tracks memory speed; if this shows 2133 or 2400 MT/s, enable XMP/DOCP in the
  BIOS.
  ```sh
  sudo dmidecode -t memory | grep -i speed
  ```
- [ ] **Confirm the GPU reaches PCIe Gen 3 x16 under load.** Check once, while a
  game is running. Gen 1 at idle is normal power saving.
  ```sh
  nvidia-smi --query-gpu=pcie.link.gen.current,pcie.link.width.current --format=csv -l 1
  ```
- [ ] **Steam → Settings → Downloads:** enable *Shader Pre-Caching* and *Allow
  background processing of Vulkan shaders*. Once. Background processing is
  also what makes a freshly installed or updated game stutter for a while;
  see Troubleshooting.
- [ ] **VRR over DisplayPort.** Optional, only if the monitor has a DP input.
  See [VRR](#vrr).
- [ ] **Install GE-Proton through ProtonPlus.** Optional. ProtonPlus is
  installed but has not installed any Proton build yet
  (`~/.local/share/Steam/compatibilitytools.d` does not exist), so
  `PROTON_DLSS_UPGRADE` does nothing until a GE-Proton is installed and
  selected for the game.

## What is automated

| What | Where | Check |
|---|---|---|
| Steam, 32-bit NVIDIA driver, GameMode, MangoHud, gamescope, protontricks | `install-gaming.sh` | `pacman -Q steam gamemode mangohud` |
| ProtonPlus (installs GE-Proton, proton-cachyos) | `install-gaming.sh` (AUR) | `protonplus` |
| ntsync | `/etc/modules-load.d/ntsync.conf` | `ls -l /dev/ntsync`; `lsof /dev/ntsync` while a Proton game runs (native Linux builds, like Valheim, never use it) |
| Memory tuning (Steam Deck community values) | `/etc/sysctl.d/99-gaming.conf` | `sysctl vm.compaction_proactiveness vm.watermark_boost_factor vm.page_lock_unfairness` |
| scx_lavd CPU scheduler, system-wide: every app runs under it, not just games | `install-scx.sh`, its own question in `install-arch.sh`; writes `/etc/scx_loader/config.toml` | `scxctl get` |
| GameMode: CPU governor, renice, I/O priority | `.config/gamemode.ini` | `gamemoded -t` |
| MangoHud: hidden until Right Shift+F12, shows GameMode status, logs to `~/mangologs` | `.config/MangoHud/MangoHud.conf`; `install-gaming.sh` creates the log folder | `gamemoded -s` while a game runs; the overlay shows the same |
| Games on a no-CoW btrfs subvolume at `~/Games` | `configure-games-subvol.sh` | `lsattr -d ~/Games` shows `C` |
| Tearing for game windows, direct scanout | `.config/hypr/UserConfigs/user_settings.lua`, `user_window_rules.lua` | `hyprctl getoption general:allow_tearing` |
| Launchers on workspace 9, games on 10 | `user_window_rules.lua` | |
| ~11 ms audio buffer. Wired output only in practice: Bluetooth (A2DP) adds far more latency than this saves | `.config/pipewire/*/10-gaming-latency.conf` | `pw-metadata -n settings 0 clock.quantum` |

The `/etc` files are written once by `install-gaming.sh` and `install-scx.sh`
and never overwritten.
To change a value, edit the file under `/etc` and the script to match.

## Launch options

Per game: Steam → game → Properties → General → Launch Options. Variables go
before the command, e.g.
`VKD3D_CONFIG=descriptor_heap gamemoderun mangohud %command%`.

Steam has no global launch options, so a new game gets neither GameMode nor
MangoHud until its line is set. ProtonPlus's Games view has a mass edit for
setting one line on many games at once.

| Option | Use when |
|---|---|
| `gamemoderun mangohud %command%` | Every game. MangoHud starts hidden. |
| `VKD3D_CONFIG=descriptor_heap` | DX12 games. Newer vkd3d-proton path that narrows NVIDIA's DX12 gap. Some games crash with it on driver 610, so compare and keep it only where it helps. |
| `PROTON_ENABLE_NVAPI=1` | DLSS or Reflex is greyed out in a game's settings. |
| `PROTON_DLSS_UPGRADE=1` | Swaps in the newest DLSS DLLs. GE-Proton or proton-cachyos only: install one through ProtonPlus and select it in the game's Properties → Compatibility first. |
| `PROTON_NO_NTSYNC=1` | Ruling ntsync out when a game hangs or regresses. |

## VRR

The monitor's EDID advertises 48–75 Hz, but over HDMI it exposes no adaptive
sync, and RTX 20-series cards do not do VRR over HDMI on a display like this.
`hyprctl monitors` reports `vrr: false`.

- **Staying on HDMI is fine.** Tearing for game windows is already enabled,
  which is the low-latency path without VRR. Nothing to do.
- **If the monitor has a DP input,** move the cable to the GPU's DisplayPort.
  Hyprland already has `vrr = 2` (fullscreen only), so no config change is
  needed. Verify with `hyprctl monitors | grep vrr`. The output name changes
  from `HDMI-A-1` to `DP-1`; the active `lua/monitors.lua` matches any output
  and keeps `highrr` (75 Hz), so nothing breaks. Only the unused
  `Monitor_Profiles/HDMI-A-1-HighRefreshRate.lua` names the port, so copy it to
  a `DP-1` profile before picking it with SUPER+SHIFT+E.
- 48–75 Hz is a narrow range: below 48 fps VRR stops helping, so aim to stay
  above it.

## Troubleshooting

| Symptom | Try first |
|---|---|
| Black screen in a fullscreen game, or stutter when the cursor shows or hides | Set `render.direct_scanout = 0` in `.config/hypr/UserConfigs/user_settings.lua` |
| Stutter right after installing or updating a game | Steam is still compiling Vulkan shaders in the background (`pgrep -a fossilize_replay`). Let it finish. This has happened on this machine; scx_lavd is meant to soften it but has not been tested for that here. |
| A native Linux game misses workspace 10 (and tearing) | Its window class is not tagged. Find it with `hyprctl clients` and add a rule next to `tag-games-native-unity` in `user_window_rules.lua`, which only catches Unity's `*.x86_64` classes. |
| A game opens windowed | Hyprland does not force games fullscreen. Use the game's own fullscreen setting; tearing and direct scanout only apply to fullscreen windows. |
| Audio crackles | Delete `.config/pipewire/*/10-gaming-latency.conf`, then `systemctl --user restart pipewire pipewire-pulse` |
| A game hangs or regressed | `PROTON_NO_NTSYNC=1 %command%` |
| DX12 game crashes with `VK_ERROR_DEVICE_LOST` | Remove `VKD3D_CONFIG=descriptor_heap` |
| Everything feels worse since scx | `sudo systemctl disable --now scx_loader`; the kernel's default scheduler takes over |
| GameMode seems inactive | Run `gamemoded -s` while the game runs. Usually the game's launch options lack `gamemoderun`. If they have it, `gamemoded -t`: the user must be in the `gamemode` group and have logged in again since. |
| Left Shift+F2 logs nothing | Show the overlay first (Right Shift+F12); logging only records while it is visible. `~/mangologs` must exist, since MangoHud will not create it. |
| Games stop launching after a driver update | `pacman -Q nvidia-utils lib32-nvidia-utils`; the versions must match |

## Revisit when

- **The monitor or GPU changes.** VRR, HDMI 2.1 and resizable BAR all depend on
  the hardware (the RTX 2060 has no resizable BAR).
- **vkd3d-proton makes descriptor heap the default.** Drop the per-game
  variable.
- **A new Proton major version ships.** Re-check which variables above still
  apply.
- **After every kernel upgrade.** Check `cat /sys/kernel/sched_ext/state` still
  says `enabled`. lavd 1.1.2 uses interfaces the kernel already logs as
  deprecated, so a future kernel may drop them; the system then silently runs
  the default scheduler.
- **Switching off the stock `linux` kernel.** Confirm the new one has
  `CONFIG_NTSYNC` and `CONFIG_SCHED_CLASS_EXT`:
  `zgrep -E 'NTSYNC|SCHED_CLASS_EXT' /proc/config.gz`.

## References

- [Hyprland: tearing](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/)
- [Hyprland: direct scanout black screen (#14843)](https://github.com/hyprwm/Hyprland/discussions/14843),
  [scanout and tearing stutter (#14124)](https://github.com/hyprwm/Hyprland/discussions/14124)
- [VKD3D-Proton descriptor heap support](https://www.phoronix.com/news/VKD3D-Proton-Descriptor-Heaps)
- [ntsync permissions (why no udev rule is needed)](https://www.phoronix.com/news/Linux-NTSYNC-Permissions-Issue)
- [scx_loader](https://github.com/sched-ext/scx-loader)
