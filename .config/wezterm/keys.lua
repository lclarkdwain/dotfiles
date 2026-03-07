local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

---@param config Config
function M.setup(config)
  config.keys = {
    -- Tab management
    { key = "t", mods = "ALT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "ALT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
    { key = "n", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
    { key = "p", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },
    -- Pane management
    { key = "v", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
    -- Pane navigation
    { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
  }
end

return M
