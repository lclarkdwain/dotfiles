local M = {}

local function is_nvidia_gpu()
  local handle = io.popen("lspci | grep -i nvidia")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

---@param config Config
function M.setup(config)
  -- NVIDIA optimization settings
  config.enable_wayland = not is_nvidia_gpu()
  config.front_end = "OpenGL"
  config.webgpu_power_preference = "HighPerformance"
  config.prefer_egl = true
  config.freetype_load_target = "Light"
  config.freetype_render_target = "HorizontalLcd"
end

return M
