local wezterm = require("wezterm") --[[@as Wezterm]]
local act = wezterm.action
local M = {}

-- Panes spawned in this domain live in a wezterm-mux-server that outlives the
-- GUI: close the window, reopen, and they are still running (gui-startup in
-- events.lua reattaches; ALT+a does it by hand). The server auto-starts on
-- first use and dies on logout, not on window close.
M.domain = "unix"

-- Git repos two levels down, e.g. ~/code/<group>/<repo>, plus ~/.dotfiles.
-- Discovered at runtime so no project names are tracked here.
local function projects()
  local home = os.getenv("HOME")
  local choices = {}
  local gits = wezterm.glob(home .. "/code/*/*/.git")
  for _, git in ipairs(wezterm.glob(home .. "/.dotfiles/.git")) do
    table.insert(gits, git)
  end
  for _, git in ipairs(gits) do
    local dir = git:gsub("/%.git$", "")
    table.insert(choices, { id = dir, label = (dir:gsub("^" .. home, "~")) })
  end
  table.sort(choices, function(a, b)
    return a.label < b.label
  end)
  return choices
end

-- One workspace per project, named after the repo, spawned in the persistent
-- domain. Picking a project that already has a workspace just switches to it.
M.pick_project = wezterm.action_callback(function(window, pane)
  window:perform_action(
    act.InputSelector({
      title = "Project",
      fuzzy = true,
      choices = projects(),
      action = wezterm.action_callback(function(win, p, dir)
        if not dir then
          return
        end
        win:perform_action(
          act.SwitchToWorkspace({
            name = dir:match("([^/]+)$"),
            spawn = { cwd = dir, domain = { DomainName = M.domain } },
          }),
          p
        )
      end),
    }),
    pane
  )
end)

---@param config Config
function M.setup(config)
  config.unix_domains = { { name = M.domain } }
end

return M
