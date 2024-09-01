local wezterm = require("wezterm") --[[@as Wezterm]]
local config = wezterm.config_builder()

config.default_domain = "WSL:Ubuntu-24.04"

package.path = package.path .. ";" .. wezterm.config_dir .. "/?.lua"

require("mouse").setup(config)
require("links").setup(config)

config.warn_about_missing_glyphs = false

-- config.front_end = "WebGpu"
-- config.front_end = "OpenGL" -- current work-around for https://github.com/wez/wezterm/issues/4825
config.enable_wayland = true
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

-- Fonts
config.font_size = 10
config.font = wezterm.font({ family = "Fira Code" })
config.bold_brightens_ansi_colors = true
config.font_rules = {
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font({ family = "Maple Mono", weight = "Bold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Half",
    font = wezterm.font({ family = "Maple Mono", weight = "DemiBold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Normal",
    font = wezterm.font({ family = "Maple Mono", style = "Italic" }),
  },
}

-- Command Palette
config.command_palette_font_size = 13
config.command_palette_bg_color = "#394b70"
config.command_palette_fg_color = "#828bb8"

return config
