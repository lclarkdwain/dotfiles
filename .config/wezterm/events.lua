local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

-- Pending resize settle per window; a newer resize supersedes older ones.
local resize_generation = {}

-- Re-sends the pane size to the mux by shrinking one column, then restoring.
local function nudge_size(window)
  local overrides = window:get_config_overrides() or {}
  local nudged = {}
  for k, v in pairs(overrides) do
    nudged[k] = v
  end
  nudged.window_padding = { left = 0, right = "1cell", top = 0, bottom = 0 }
  window:set_config_overrides(nudged)
  wezterm.time.call_after(0.1, function()
    window:set_config_overrides(overrides)
  end)
end

function M.setup()
  -- Mux panes can keep a stale size after a burst of tiling resizes.
  wezterm.on("window-resized", function(window)
    local id = window:window_id()
    local generation = (resize_generation[id] or 0) + 1
    resize_generation[id] = generation
    wezterm.time.call_after(0.5, function()
      if resize_generation[id] == generation then
        nudge_size(window)
      end
    end)
  end)

  wezterm.on("new-tab-button-click", function(window, pane)
    window:perform_action(wezterm.action.SpawnCommandInNewTab({ cwd = "~" }), pane)
    return false
  end)

  wezterm.on("format-tab-title", function(tab)
    local process = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
    local cwd = tab.active_pane.current_working_dir
    cwd = cwd and string.format("%s ", cwd.file_path:gsub(os.getenv("HOME"), "~")) or ""
    local vars = tab.active_pane.user_vars or {}
    local badge = ""
    if vars.claude_account == "work" then
      badge = "󰃖 WORK "
    elseif vars.claude_account == "personal" then
      badge = "󰀄 PERSONAL "
    end
    return string.format("%s(%d %s) %s", badge, tab.tab_index + 1, process, cwd)
  end)

  wezterm.on("update-status", function(window)
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    local sections = {
      window:active_workspace(),
      wezterm.hostname(),
    }
    local color_scheme = window:effective_config().resolved_palette
    local bg = wezterm.color.parse(color_scheme.background)
    local fg = color_scheme.foreground
    local gradient_to = bg
    local gradient_from = gradient_to:lighten(0.2)
    local gradients = wezterm.color.gradient({
      orientation = "Horizontal",
      colors = { gradient_from, gradient_to },
    }, #sections)
    local elements = {}
    for i, sec in ipairs(sections) do
      if i == 1 then
        table.insert(elements, { Background = { Color = "none" } })
      end
      table.insert(elements, { Foreground = { Color = gradients[i] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
      table.insert(elements, { Foreground = { Color = fg } })
      table.insert(elements, { Background = { Color = gradients[i] } })
      table.insert(elements, { Text = " " .. sec .. " " })
    end
    window:set_right_status(wezterm.format(elements))
  end)
end

return M
