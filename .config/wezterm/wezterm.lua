local wezterm = require("wezterm") --[[@as Wezterm]]
local config = wezterm.config_builder()

-- uncomment to use WSL as default domain
-- package.path = package.path .. ";" .. wezterm.config_dir .. "/?.lua"
-- config.default_domain = "WSL:Ubuntu"

require("mouse").setup(config)
require("links").setup(config)
require("nvidia").setup(config)
require("appearance").setup(config)
require("fonts").setup(config)
require("mux").setup(config)
require("keys").setup(config)
require("events").setup()

config.warn_about_missing_glyphs = false

-- config.front_end = "Software"
-- config.front_end = "OpenGL" -- current work-around for https://github.com/wez/wezterm/issues/4825
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
-- config.enable_wayland = true

-- GPU
-- local gpus = wezterm.gui.enumerate_gpus()
-- config.webgpu_preferred_adapter = gpus[1]
-- config.webgpu_power_preference = "HighPerformance"
-- config.webgpu_force_fallback_adapter = true
-- config.front_end = "WebGpu"

-- Smoother
-- config.max_fps = 100

-- Support for undercurl, etc.
-- config.term = "wezterm"

return config
