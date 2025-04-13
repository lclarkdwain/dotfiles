local wezterm = require("wezterm") --[[@as Wezterm]]
local mux = wezterm.mux
local config = wezterm.config_builder()

package.path = package.path .. ";" .. wezterm.config_dir .. "/?.lua"

require("mouse").setup(config)
require("links").setup(config)

config.warn_about_missing_glyphs = false

-- config.front_end = "WebGpu"
config.front_end = "OpenGL" -- current work-around for https://github.com/wez/wezterm/issues/4825
config.enable_wayland = false
config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Colorscheme
config.color_scheme = "carbonfox"

config.colors = {
  indexed = { [241] = "#65bcff" },
}

config.window_background_opacity = 0.9
-- Only keep the resizable border
config.window_decorations = "RESIZE"

-- Fonts
config.font_size = 10
config.font = wezterm.font({ family = "Maple Mono NF" })
config.bold_brightens_ansi_colors = true
config.font_rules = {
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font({ family = "Maple Mono NF", weight = "Bold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Half",
    font = wezterm.font({ family = "Maple Mono NF", weight = "DemiBold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Normal",
    font = wezterm.font({ family = "Maple Mono NF", style = "Italic" }),
  },
}
-- Disable ligatures
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Adjust underline style
config.underline_position = -6
config.underline_thickness = "150%"

-- Remove extra space
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- Command Palette
config.command_palette_font_size = 13
config.command_palette_bg_color = "#394b70"
config.command_palette_fg_color = "#828bb8"

-- Tab bar
config.window_frame = {
  font = wezterm.font("Maple Mono", { weight = "Bold" }),
  font_size = 9,
}

-- Gui startup
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Tab bar title
wezterm.on("format-tab-title", function(tab)
  -- Get the process name.
  local process = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
  -- Current working directory.
  local cwd = tab.active_pane.current_working_dir
  cwd = cwd and string.format("%s ", cwd.file_path:gsub(os.getenv("HOME"), "~")) or ""
  -- Format and return the title.
  return string.format("(%d %s) %s", tab.tab_index + 1, process, cwd)
end)

-- Status bar
-- Name of the current workspace | Hostname
wezterm.on("update-status", function(window)
  -- utf8 character for the powerline left solid arrow
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  --Add what will be displayed on the status bar here
  local sections = {
    window:active_workspace(),
    wezterm.hostname(),
  }
  -- Get the palette of the current color theme
  local color_scheme = window:effective_config().resolved_palette
  -- parse returns a Color object that has functions for lightening and darkening
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground
  -- Create gradients for the background color of each section
  local gradient_to = bg
  local gradient_from = gradient_to:lighten(0.2)
  local gradients = wezterm.color.gradient({
    orientation = "Horizontal",
    colors = { gradient_from, gradient_to },
  }, #sections)
  -- Render
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

return config
