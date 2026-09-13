-- LOCAL FIX: laptop binds ported from Laptops.conf (ASUS-only keys dropped)

local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scriptsDir = configHome .. "/hypr/scripts"

local function bind(mods, key, cmd, opts)
  local chord = mods == "" and key or (mods:gsub("%s+", " + ") .. " + " .. key)
  hl.bind(chord, hl.dsp.exec_cmd(cmd), opts)
end

bind("", "XF86MonBrightnessUp", scriptsDir .. "/Brightness.sh --inc", { description = "screen brightness up", locked = true, repeating = true })
bind("", "XF86MonBrightnessDown", scriptsDir .. "/Brightness.sh --dec", { description = "screen brightness down", locked = true, repeating = true })
bind("", "XF86KbdBrightnessUp", scriptsDir .. "/BrightnessKbd.sh --inc", { description = "keyboard backlight up", locked = true, repeating = true })
bind("", "XF86KbdBrightnessDown", scriptsDir .. "/BrightnessKbd.sh --dec", { description = "keyboard backlight down", locked = true, repeating = true })
bind("", "XF86TouchpadToggle", scriptsDir .. "/TouchPad.sh", { description = "toggle touchpad" })

-- For laptops without a Print key
bind("SUPER", "F6", scriptsDir .. "/ScreenShot.sh --now", { description = "screenshot now" })
bind("SUPER SHIFT", "F6", scriptsDir .. "/ScreenShot.sh --area", { description = "screenshot (area)" })
bind("SUPER CTRL", "F6", scriptsDir .. "/ScreenShot.sh --in5", { description = "screenshot in 5s" })
bind("SUPER ALT", "F6", scriptsDir .. "/ScreenShot.sh --in10", { description = "screenshot in 10s" })
bind("ALT", "F6", scriptsDir .. "/ScreenShot.sh --active", { description = "screenshot active window" })

-- Keep a touchpad disabled by TouchPad.sh across reloads
local runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local state = io.open(runtime .. "/touchpad.disabled", "r")
if state then
  local device = state:read("*l")
  state:close()
  if device and device ~= "" then
    hl.device({ name = device, enabled = false })
  end
end
