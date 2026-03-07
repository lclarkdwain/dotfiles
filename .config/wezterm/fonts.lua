local wezterm = require("wezterm") --[[@as Wezterm]]
local M = {}

---@param config Config
function M.setup(config)
  config.font_size = 10
  -- config.font_size = 12

  config.font = wezterm.font({ family = "Maple Mono NF" })
  -- font with fallback
  -- config.font = wezterm.font_with_fallback({
  --   { family = "Fira Code", weight = 250, stretch = "Normal", style = "Normal" },
  --   "Fira Code",
  --   "JetBrains Mono",
  --   "Hack",
  -- })

  config.bold_brightens_ansi_colors = true
  -- config.bold_brightens_ansi_colors = false

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
  config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
  config.underline_position = -6
  config.underline_thickness = "150%"

  config.window_frame = {
    font = wezterm.font("Maple Mono NF", { weight = "Bold" }),
    font_size = 9,
  }
  -- config.window_frame = {
  --   font = wezterm.font({ family = "JetBrainsMono Nerd Font Mono", weight = "Regular" }),
  -- }
end

return M
