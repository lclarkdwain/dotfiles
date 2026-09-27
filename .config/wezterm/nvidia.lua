local M = {}

---@param config Config
function M.setup(config)
  -- NVIDIA optimization settings
  config.enable_wayland = true
  config.front_end = "OpenGL"
  config.webgpu_power_preference = "HighPerformance"
  config.prefer_egl = true
  config.freetype_load_target = "Light"
  config.freetype_render_target = "HorizontalLcd"
end

return M
