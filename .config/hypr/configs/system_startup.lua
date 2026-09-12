-- System defaults migrated from configs/Startup_Apps.conf (auto-generated).
-- Add commands with exec_once("your command")
-- Example:
-- exec_once("swaync")

local session = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"

local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scriptsDir = configHome .. "/hypr/scripts"

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function exec_once(cmd)
  local key = cmd:gsub("[^%w_.-]", "_"):sub(1, 80)
  local marker = "/tmp/hypr-lua-system-exec-once-" .. session .. "-" .. key
  local log = "/tmp/hypr-lua-system-startup-" .. key .. ".log"
  local readiness = "runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}; export XDG_RUNTIME_DIR=\"$runtime\"; for _ in $(seq 1 200); do if [ -n \"$WAYLAND_DISPLAY\" ] && [ -S \"$runtime/$WAYLAND_DISPLAY\" ]; then break; fi; for sock in \"$runtime\"/wayland-[0-9]*; do [ -S \"$sock\" ] || continue; case \"$(basename \"$sock\")\" in *awww*) continue ;; esac; export WAYLAND_DISPLAY=\"$(basename \"$sock\")\"; break 2; done; sleep 0.1; done; if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then hypr_sock=\"$runtime/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock\"; for _ in $(seq 1 200); do [ -S \"$hypr_sock\" ] && break; sleep 0.1; done; fi"
  local inner = readiness .. "; " .. cmd
  local script = "[ -e " .. shell_quote(marker) .. " ] || { touch " .. shell_quote(marker) .. " && sh -lc " .. shell_quote(inner) .. " >>" .. shell_quote(log) .. " 2>&1 & }"
  os.execute("sh -lc " .. shell_quote(script))
end

-- Converted from configs/Startup_Apps.conf
local startup_commands = {
  -- Retired: caelestia draws the wallpaper now, so awww-daemon would fight it.
  -- scriptsDir .. "/WallpaperDaemon.sh",
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE",
  -- Chained, not a separate entry: exec_once backgrounds each command, so the target would race the import.
  "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target",
  -- --startup keeps it hidden; terminal must match the SUPER SHIFT Return bind
  scriptsDir .. "/Dropterminal.sh --startup wezterm",
  scriptsDir .. "/Polkit.sh",
  "nm-applet --indicator",
  -- swaync retired: caelestia owns the notification bus. swaync.service is disabled, not removed.
  -- -l error: the network#speed module polls nl80211 every second on wlp6s0 and
  -- the driver returns EBUSY, emitting "nl80211: nl_send_sync get_station
  -- error -16" ~1x/sec. It is cosmetic (the module works) but it floods the log
  -- and grows unbounded, burying real diagnostics. Warnings are suppressed;
  -- [error] lines (e.g. cava_mviz, power-profiles-daemon) still show.
  -- Retired: caelestia owns the bar. Re-enable by uncommenting and commenting caelestia below.
  -- "waybar -l error",
  "caelestia shell -d",
  "qs -c overview",
  "hypridle",
  scriptsDir .. "/Hyprsunset.sh init",
  "wl-paste --type text --watch cliphist store",
  "wl-paste --type image --watch cliphist store",
  "blueman-applet",
  scriptsDir .. "/KeybindsLayoutInit.sh",
}

local function run_startup_commands()
  for _, cmd in ipairs(startup_commands) do
    exec_once(cmd)
  end
end

if hl and hl.on then
  hl.on("hyprland.start", run_startup_commands)
else
  run_startup_commands()
end
