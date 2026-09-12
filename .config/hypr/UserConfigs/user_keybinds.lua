-- User keybind overrides (auto-generated).
-- Add keybinds with bind("MODS", "KEY", fn, opts).
-- Example:
-- bind("SUPER", "Z", exec_cmd("ghostty"), { description = "Launch ghostty" })
-- Helper functions live in ${XDG_CONFIG_HOME:-$HOME/.config}/hypr/lua/user_keybinds_helper.lua so they can be updated separately.
local user_keybinds_helper = nil
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""
  local candidate_paths = {
    source_dir and (source_dir .. "/../lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/user_keybinds_helper.lua") or nil,
  }

  local tried_paths = {}
  for _, helper_path in ipairs(candidate_paths) do
    if helper_path then
      table.insert(tried_paths, helper_path)
      local f = io.open(helper_path, "r")
      if f then
        f:close()
        local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
        if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.bind then
          user_keybinds_helper = loaded_helpers
          break
        end
      end
    end
  end

  if not user_keybinds_helper then
    error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths, ", "))
  end
end
local exec_cmd = user_keybinds_helper.exec_cmd
local dispatch = user_keybinds_helper.dispatch
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind

-- No active keybind entries were found in UserKeybinds.conf.
-- bind("SUPER", "Z", exec_cmd("thunar"), { description = "Open file manager" })

-- Parked with the sysmon panel while caelestia is trialled.
-- bind("SUPER SHIFT", "D", exec_cmd("qs -c sysmon ipc call panel toggle"), { description = "toggle system monitor panel" })
bind("SUPER SHIFT", "Y", exec_cmd("wezterm start --class sysdiag-report -- sh -c '$HOME/.local/bin/sysdiag; printf \"\\npress enter to close\"; read -r _'"), { description = "system health report" })

-- Waybar is retired, so its menus would restart it on top of caelestia.
unbind("SUPER CTRL", "B")
unbind("SUPER ALT", "B")

-- Same hazard: Refresh.sh restarts waybar. RefreshNoWaybar.sh is the existing variant that does not.
unbind("SUPER ALT", "R")
bind("SUPER ALT", "R", exec_cmd("$HOME/.config/hypr/scripts/RefreshNoWaybar.sh"), { description = "refresh menus" })

-- Caelestia registers ~22 D-Bus global shortcuts but binds no keys to them; without
-- these the launcher, dashboard, sidebar and OSD are unreachable.
local function global(name)
  return exec_cmd("hyprctl dispatch 'hl.dsp.global(\"caelestia:" .. name .. "\")'")
end

bind("SUPER", "space", global("launcher"), { description = "caelestia launcher" })
bind("SUPER SHIFT", "space", global("showall"), { description = "caelestia launcher + dashboard + osd" })
bind("SUPER", "K", global("dashboard"), { description = "caelestia dashboard" })
bind("SUPER", "grave", global("nexus"), { description = "caelestia nexus" })
bind("CTRL ALT", "C", global("clearNotifs"), { description = "clear notifications" })
bind("SUPER", "escape", global("session"), { description = "caelestia session menu" })

-- Reclaims the dead swaync binding: swaync is retired, so this opened nothing.
unbind("SUPER SHIFT", "N")
bind("SUPER SHIFT", "N", global("sidebar"), { description = "caelestia sidebar" })

-- Volume goes straight to wpctl so caelestia's OSD picks it up; Volume.sh drew its own
-- notify-send popup instead, which is why the slider never appeared.
unbind("", "xf86audioraisevolume")
unbind("", "xf86audiolowervolume")
unbind("", "xf86audiomute")
bind("", "xf86audioraisevolume", exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { description = "volume up", locked = true, repeating = true })
bind("", "xf86audiolowervolume", exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { description = "volume down", locked = true, repeating = true })
bind("", "xf86audiomute", exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "mute", locked = true })

-- Media and brightness through caelestia so they share the same OSD.
unbind("", "xf86audioplay")
unbind("", "xf86audionext")
unbind("", "xf86audioprev")
unbind("", "xf86audiostop")
bind("", "xf86audioplay", global("mediaToggle"), { description = "play/pause", locked = true })
bind("", "xf86audionext", global("mediaNext"), { description = "next track", locked = true })
bind("", "xf86audioprev", global("mediaPrev"), { description = "previous track", locked = true })
bind("", "xf86audiostop", global("mediaStop"), { description = "stop", locked = true })

-- The ALT "precise" variants still called Volume.sh, so they kept the old popup.
unbind("ALT", "xf86audioraisevolume")
unbind("ALT", "xf86audiolowervolume")
bind("ALT", "xf86audioraisevolume", exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"), { description = "volume up precise", locked = true, repeating = true })
bind("ALT", "xf86audiolowervolume", exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { description = "volume down precise", locked = true, repeating = true })
