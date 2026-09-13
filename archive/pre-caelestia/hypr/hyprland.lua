-- KoolDots Hyprland Lua config entrypoint.
-- Mirrors hyprland.conf include order for features currently supported by Lua config.
local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr"

local function load_module(name)
  dofile(hyprDir .. "/lua/" .. name .. ".lua")
end

-- In Lua workflow, runtime config is loaded from split files under:
--   ~/.config/hypr/configs/system_*.lua
--   ~/.config/hypr/UserConfigs/user_*.lua
-- via lua/user_overrides.lua. lua/ holds only the loaders and helpers; upstream's
-- template copies of the system_*.lua files were removed because they were never
-- loaded and kept drifting from the real ones.
load_module("user_defaults")
load_module("user_overrides")
load_module("monitors")
load_module("workspaces")
