-- User window rule overrides (auto-generated).
-- Add your own rules with apply_window_rule({...})
-- Example:
-- apply_window_rule({
--   name = "My Float Rule",
--   match = { class = "^pavucontrol$" },
--   float = true,
--   center = true,
-- })

local user_window_rules_helper = nil
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""
  local candidate_paths = {
    source_dir and (source_dir .. "/../lua/user_window_rules_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/lua/user_window_rules_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/user_window_rules_helper.lua") or nil,
  }

  local tried_paths = {}
  for _, helper_path in ipairs(candidate_paths) do
    if helper_path then
      table.insert(tried_paths, helper_path)
      local f = io.open(helper_path, "r")
      if f then
        f:close()
        local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
        if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.apply_window_rule then
          user_window_rules_helper = loaded_helpers
          break
        end
      end
    end
  end

  if not user_window_rules_helper then
    error("Failed to load user_window_rules_helper.lua from: " .. table.concat(tried_paths, ", "))
  end
end
local apply_window_rule = user_window_rules_helper.apply_window_rule

-- Converted from WindowRules.conf
apply_window_rule({
  name = "user-window-windowrule-001",
  match = {
    tag = "terminal",
  },
  workspace = 1,
})

apply_window_rule({
  name = "user-window-windowrule-002",
  match = {
    tag = "projects",
  },
  workspace = 2,
})

apply_window_rule({
  name = "user-window-windowrule-003",
  match = {
    class = "^(Emulator)$",
  },
  workspace = 2,
  float = 1,
})

apply_window_rule({
  name = "user-window-windowrule-004",
  match = {
    class = "^(zen|firefox|Firefox)$",
  },
  workspace = 3,
})

apply_window_rule({
  name = "user-window-windowrule-005",
  match = {
    class = "^(chromium|google-chrome|brave-browser)$",
  },
  workspace = 4,
})

apply_window_rule({
  name = "user-window-windowrule-006",
  match = {
    tag = "file-manager",
  },
  workspace = 5,
})

apply_window_rule({
  name = "user-window-windowrule-007",
  match = {
    tag = "im",
  },
  workspace = 6,
})

apply_window_rule({
  name = "user-window-windowrule-008",
  match = {
    title = "^(btop|lazydocker|docker-desktop)$",
  },
  workspace = 7,
})

apply_window_rule({
  name = "user-window-windowrule-009",
  match = {
    class = "^(obsidian|Obsidian)$",
  },
  workspace = 8,
})

-- ---------------------------------------------------------------------------
-- Gaming: scope tearing to game windows
-- ---------------------------------------------------------------------------

-- The `games` tag is applied in configs/system_window_rules.lua to gamescope,
-- steam_app_<id> and Proton windows. Pairing it with `immediate` keeps the
-- tearing opt-in confined to games; everything else still presents on the
-- vblank. Requires general.allow_tearing, set in user_settings.lua -- neither
-- half does anything without the other.
--
-- `immediate` is absent from hl.meta.lua. That file is an incomplete annotation
-- set, not the API surface: hl.window_rule validates and rejects unknown fields
-- outright ("hl.window_rule: unknown field '...'"), and it accepts this one.
apply_window_rule({
  name = "games-allow-tearing",
  match = {
    tag = "games",
  },
  immediate = true,
})

-- Send launchers and games to their own workspaces.
--
-- Both tags come from configs/system_window_rules.lua: `gamestore` is the
-- Steam/Lutris/Heroic client windows, `games` is gamescope, steam_app_<id> and
-- Proton game windows. Splitting them keeps the launcher available on 9 while a
-- game has 10 to itself, rather than a game replacing the client you launched
-- it from.
--
-- Plain integers, matching the assignments above. Hyprland's "N silent" form
-- may well work, but hl.window_rule does not validate this field's value (it
-- accepts outright nonsense here, unlike opacity), so `ok` from the API would
-- not have confirmed it.
apply_window_rule({
  name = "gamestore-workspace",
  match = {
    tag = "gamestore",
  },
  workspace = 9,
})

apply_window_rule({
  name = "games-workspace",
  match = {
    tag = "games",
  },
  workspace = 10,
})

-- Steam's login window opens off-screen.
--
-- configs/system_window_rules.lua rule 065 floats any steam window whose title
-- is not exactly "Steam". That is correct, but it sets no position, so the
-- login window lands wherever Steam asks -- which is a negative x, leaving it
-- clipped off the left edge of the monitor and awkward to interact with.
--
-- Scoped to this one title on purpose. Adding center to rule 065 itself would
-- also drag Steam's toast notifications into the middle of the screen, since
-- those are class steam with a non-"Steam" title too.
--
-- Substring rather than an anchored match: the exact title could not be
-- verified live (it only appears while logged out), so this is deliberately
-- forgiving about surrounding text.
apply_window_rule({
  name = "steam-signin-center",
  match = {
    class = "^([Ss]team)$",
    title = "(Sign in to Steam)",
  },
  float = true,
  center = true,
})
