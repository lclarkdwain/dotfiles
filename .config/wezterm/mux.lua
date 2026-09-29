local wezterm = require("wezterm") --[[@as Wezterm]]
local act = wezterm.action
local M = {}

-- Project shells live in a wezterm-mux-server that outlives any window: close
-- a project window and its panes keep running; ALT+p on the project brings
-- them back. The server auto-starts on first use and dies on logout. Exiting
-- the last shell (or ALT+q) ends the project for good.
M.domain = "unix"
M.socket = (os.getenv("XDG_RUNTIME_DIR") or wezterm.home_dir) .. "/wezterm/sock"

local function cli(...)
  return wezterm.run_child_process({ "env", "WEZTERM_UNIX_SOCKET=" .. M.socket, "wezterm", "cli", ... })
end

-- Git repos two levels down, e.g. ~/code/<group>/<repo>. Discovered at runtime
-- so no project names are tracked here.
local function projects()
  local home = wezterm.home_dir
  local choices = {}
  for _, git in ipairs(wezterm.glob(home .. "/code/*/*/.git")) do
    local dir = git:gsub("/%.git$", "")
    table.insert(choices, { id = dir, label = (dir:gsub("^" .. home, "~")) })
  end
  table.sort(choices, function(a, b)
    return a.label < b.label
  end)
  return choices
end

-- Each project window is its own `wezterm connect unix --workspace <name>`
-- process, so its Hyprland window is found by that process's arguments.
local function focus_existing(name)
  if not os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
    return false
  end
  local ok, out = wezterm.run_child_process({ "hyprctl", "clients", "-j" })
  if not ok then
    return false
  end
  for _, client in ipairs(wezterm.serde.json_decode(out)) do
    local f = io.open("/proc/" .. client.pid .. "/cmdline")
    local cmdline = f and f:read("a") or ""
    if f then
      f:close()
    end
    if cmdline:find("\0connect\0" .. M.domain .. "\0", 1, true) and cmdline:find("\0--workspace\0" .. name .. "\0", 1, true) then
      wezterm.run_child_process({
        "hyprctl",
        "dispatch",
        string.format('hl.dsp.focus({ window = "address:%s" })', client.address),
      })
      return true
    end
  end
  return false
end

local function has_panes(name)
  local ok, out = cli("list", "--format", "json")
  if not ok then
    return false
  end
  for _, p in ipairs(wezterm.serde.json_decode(out)) do
    if p.workspace == name then
      return true
    end
  end
  return false
end

-- One Hyprland window per project. Deliberately not a WezTerm workspace switch
-- in this window: that shows one project at a time and hides every other
-- WezTerm window, which fights Hyprland.
local function open_project(dir)
  local name = dir:match("([^/]+)$")
  if focus_existing(name) then
    return
  end
  -- `connect` has no --cwd, so seed the workspace in the right folder first.
  if not has_panes(name) then
    cli("spawn", "--new-window", "--workspace", name, "--cwd", dir)
  end
  wezterm.background_child_process({ "wezterm", "connect", M.domain, "--workspace", name })
end

M.pick_project = wezterm.action_callback(function(window, pane)
  window:perform_action(
    act.InputSelector({
      title = "Project",
      fuzzy = true,
      choices = projects(),
      action = wezterm.action_callback(function(_, _, dir)
        if dir then
          open_project(dir)
        end
      end),
    }),
    pane
  )
end)

---@param config Config
function M.setup(config)
  config.unix_domains = { { name = M.domain, socket_path = M.socket } }
end

return M
