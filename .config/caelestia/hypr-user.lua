-- Personal overrides, loaded last by ~/.config/hypr/hyprland.lua (upstream, kept untouched).

local home = os.getenv("HOME")

-- Monitors: "preferred" drops to 60 Hz and "highrr" to 1024x768
hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

hl.monitor({
  output = "desc:HKC OVERSEAS LIMITED 34E6UC 0000000000001",
  mode = "3440x1440@180",
  position = "0x0",
  scale = 1,
})

-- Laptop + external: panel off, external is main. Desktop: defaults. Read from DRM (disabled panels aren't Hyprland monitors)
local internal_prefixes = { "eDP", "LVDS", "DSI" }
local function connected_outputs()
  local internal, external = {}, {}
  local ok, p = pcall(io.popen, "grep -lx connected /sys/class/drm/card*-*/status 2>/dev/null")
  if not ok or not p then
    return internal, external
  end
  local out = p:read("*a") or ""
  p:close()
  for name in out:gmatch("card%d+%-([^/]+)/status") do
    local is_internal = false
    for _, prefix in ipairs(internal_prefixes) do
      if name:sub(1, #prefix) == prefix then
        is_internal = true
      end
    end
    table.insert(is_internal and internal or external, name)
  end
  return internal, external
end

local internal, external = connected_outputs()
local panel_off = #internal > 0 and #external > 0
if #internal > 0 then
  for _, panel in ipairs(internal) do
    hl.monitor({ output = panel, mode = "highres", position = "auto-left", scale = 1, disabled = panel_off })
  end
  if panel_off then
    local main = external[1]
    for ws = 1, 10 do
      hl.workspace_rule({ workspace = tostring(ws), monitor = main, default = ws == 1 })
    end
    hl.config({ cursor = { default_monitor = main } })
  end

  -- Hotplug: reload only on change (no loop); restart shell, its bar breaks when an output vanishes.
  -- flock queues the runs a replug fires back to back, so one can't kill the shell another just started
  local on_hotplug = 'flock "${XDG_RUNTIME_DIR:-/tmp}/hypr-hotplug.lock" '
    .. '"$HOME/.local/bin/caelestia-hotplug" '
    .. tostring(panel_off)
  for _, event in ipairs({ "monitor.added", "monitor.removed" }) do
    hl.on(event, function()
      local _, now_external = connected_outputs()
      if (#now_external > 0) ~= panel_off then
        hl.exec_cmd(on_hotplug)
      end
    end)
  end
end

-- Env
if home then
  local qml_dir = home .. "/.local/lib/qt6/qml" -- caelestia QML plugin from install-caelestia.sh
  hl.env("QML2_IMPORT_PATH", qml_dir)
  hl.env("QML_IMPORT_PATH", qml_dir)
end

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

local nvidia = io.open("/proc/driver/nvidia/version", "r")
if nvidia then
  nvidia:close()
  hl.env("LIBVA_DRIVER_NAME", "nvidia")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
  hl.env("NVD_BACKEND", "direct")
  hl.env("GSK_RENDERER", "ngl")
end

-- Settings
hl.config({ input = { kb_layout = "us" } }) -- rewritten by set_kb_layout in prompts.sh

hl.config({
  general = { allow_tearing = true },
  render = { direct_scanout = 2 }, -- games only
})

-- Execs: start graphical-session.target so session units run
hl.on("hyprland.start", function()
  local vars = "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE"
  hl.exec_cmd("dbus-update-activation-environment --systemd " .. vars)
  hl.exec_cmd("systemctl --user import-environment " .. vars .. " && systemctl --user start hyprland-session.target")
  hl.exec_cmd('flock -n "${XDG_RUNTIME_DIR:-/tmp}/caelestia-watchdog.lock" "$HOME/.local/bin/caelestia-watchdog"') -- restart shell on crash
end)

-- Keybinds
hl.bind("SUPER + Return", hl.dsp.exec_cmd("wezterm"))
hl.bind("SUPER + Space", hl.dsp.global("caelestia:launcher"))
hl.bind("SUPER + Grave", hl.dsp.global("caelestia:nexus"))
hl.bind(
  "SUPER + SHIFT + Y",
  hl.dsp.exec_cmd(
    "wezterm start --class sysdiag-report -- sh -c '$HOME/.local/bin/sysdiag; printf \"\\npress enter to close\"; read -r _'"
  )
)

-- Window rules
local function to_workspace(ws, matches)
  for _, match in ipairs(matches) do
    hl.window_rule({ match = match, workspace = ws })
  end
end

to_workspace("1", { { class = "^(org.wezfurlong.wezterm|kitty|Alacritty|ghostty)$" } })
to_workspace("2", {
  { class = "^(code|code-url-handler|VSCode|codium|VSCodium)$" },
  { class = "^(jetbrains-.+|dev.zed.Zed|[Cc]ursor)$" },
})
to_workspace("3", { { class = "^(zen|firefox|Firefox)$" } })
to_workspace("4", { { class = "^(chromium|google-chrome|brave-browser)$" } })
to_workspace("5", { { class = "^([Tt]hunar|org.gnome.Nautilus)$" } })
to_workspace("8", { { class = "^([Oo]bsidian)$" } })
to_workspace("special:communication", { { class = "^([Ss]lack)$" } }) -- upstream's communication tag misses Slack
to_workspace("9", {
  { class = "^([Ss]team)$" },
  { class = "^(com.heroicgameslauncher.hgl)$" },
  { title = "^([Ll]utris)$" },
})
to_workspace("10", {
  { class = "^(steam_app_[0-9]+|gamescope)$" },
  { class = "^(.+\\.x86_64)$" },
})

-- Native Unity builds, which upstream's game tag misses
hl.window_rule({
  match = { class = "^(.+\\.x86_64)$" },
  opaque = true,
  immediate = true,
  idle_inhibit = "always",
})

-- Tag games as game content
hl.window_rule({ match = { tag = "game" }, content = "game" })
hl.window_rule({ match = { class = "^(.+\\.x86_64)$" }, content = "game" })

hl.window_rule({ match = { class = "^(Emulator)$" }, workspace = "2", float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "(Sign in to Steam)" }, float = true, center = true })
hl.window_rule({
  match = { class = "^(sysdiag-report)$" },
  float = true,
  center = true,
  size = "(monitor_w*0.5) (monitor_h*0.6)",
})

-- Machine-specific overrides, gitignored; see hypr.local.lua.example
local machine_conf = home and home .. "/.config/caelestia/hypr.local.lua"
local f = machine_conf and io.open(machine_conf)
if f then
  f:close()
  dofile(machine_conf)
end
