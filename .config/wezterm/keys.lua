local wezterm = require("wezterm") --[[@as Wezterm]]
local act = wezterm.action
local mux = require("mux")
local M = {}

-- ALT mirrors Hyprland's SUPER one level down: SUPER drives windows and
-- workspaces, ALT drives panes and tabs, with the same key doing the same job.
-- zsh runs in vi mode, so ALT+letter is otherwise just ESC+letter; ALT+Left/
-- Right (word jump) and ALT+j/k (LazyVim move line) are left alone.
---@param config Config
function M.setup(config)
  config.keys = {
    -- SUPER+Return / SUPER+T open a terminal; ALT splits one or opens a tab.
    { key = "Enter", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "Enter", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },

    -- SUPER+Q close, SUPER+F fullscreen
    { key = "q", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "f", mods = "ALT", action = act.TogglePaneZoomState },

    -- SUPER+arrows focus
    { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },

    -- SUPER+Minus/Equal width, SUPER+SHIFT+Minus/Equal height
    { key = "-", mods = "ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "=", mods = "ALT", action = act.AdjustPaneSize({ "Right", 5 }) },
    { key = "_", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "+", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },

    -- CTRL+SUPER+Left/Right cycle workspaces; CTRL+SUPER+SHIFT moves the window
    { key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
    { key = "RightArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },
    { key = "LeftArrow", mods = "CTRL|ALT|SHIFT", action = act.MoveTabRelative(-1) },
    { key = "RightArrow", mods = "CTRL|ALT|SHIFT", action = act.MoveTabRelative(1) },

    -- SUPER+Space launcher, SUPER+S special workspace, SUPER+V clipboard
    { key = "Space", mods = "ALT", action = act.ActivateCommandPalette },
    { key = "p", mods = "ALT", action = mux.pick_project },
    { key = "s", mods = "ALT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    { key = "v", mods = "ALT", action = act.ActivateCopyMode },
  }

  -- SUPER+1..9 workspaces
  for i = 1, 9 do
    table.insert(config.keys, { key = tostring(i), mods = "ALT", action = act.ActivateTab(i - 1) })
  end
end

return M
