local wezterm = require("wezterm")

local M = {}

-- Follow DarkLight.sh's mode file (watched); get_appearance() goes stale under XWayland
local mode_file = (os.getenv("HOME") or "") .. "/.cache/.theme_mode"

local function is_light()
  local f = io.open(mode_file, "r")
  if f then
    local mode = f:read("*l")
    f:close()
    wezterm.add_to_config_reload_watch_list(mode_file)
    return mode == "Light"
  end
  return wezterm.gui ~= nil and wezterm.gui.get_appearance():find("Light") ~= nil
end

---@param config Config
function M.setup(config)
  config.color_scheme = is_light() and "dayfox" or "carbonfox"
  -- config.color_scheme = "Catppuccin Mocha"

  config.colors = {
    indexed = { [241] = "#65bcff" },
    -- tab bar colors
    -- tab_bar = {
    --   active_tab = {
    --     bg_color = "#80bfff",
    --     fg_color = "#00141d",
    --   },
    --   inactive_tab = {
    --     bg_color = "#1a1a1a",
    --     fg_color = "#FFFFFF",
    --   },
    --   new_tab = {
    --     bg_color = "#1a1a1a",
    --     fg_color = "#4fc3f7",
    --   },
    -- },
  }

  config.window_background_opacity = 0.55
  -- config.window_background_opacity = 1.0

  config.win32_system_backdrop = "Acrylic"
  config.enable_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = true
  -- config.use_fancy_tab_bar = false

  config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  }
  -- config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

  config.command_palette_font_size = 13
  config.command_palette_bg_color = "#394b70"
  config.command_palette_fg_color = "#828bb8"

  config.default_cursor_style = "BlinkingUnderline"
  config.cursor_blink_rate = 500
  -- Support for undercurl, etc.
  config.term = "wezterm"
  -- config.term = "xterm-256color" -- commented out since we may use wezterm term
  config.max_fps = 120
  config.animation_fps = 30
end

return M
