-- User settings overrides template.
-- Add your personal hl.config(...) values here.

-- Example:
-- hl.config({
--   general = {
--     gaps_in = 4,
--     gaps_out = 8,
--     border_size = 1,
--   },
-- })
--

-- Disable cursor being centered when swap workspaces
--
-- hl.config({
-- 	cursor = {
-- 		no_warps = true,
-- 		warp_on_change_workspace = 0,
-- 	},
-- })

-- ---------------------------------------------------------------------------
-- Gaming: latency and presentation
-- ---------------------------------------------------------------------------

-- allow_tearing is only the global gate -- on its own it changes nothing. A
-- window must ALSO carry the `immediate` rule, which user_window_rules.lua
-- applies to the `games` tag. So this stays scoped to games; desktop windows
-- keep presenting on the vblank.
--
-- This matters on this machine specifically: HDMI-A-1 reports vrr: false, so
-- there is no adaptive sync to smooth frame delivery. Letting a game present
-- mid-scanout is the remaining way to drop a frame of input latency.
--
-- direct_scanout lets a fullscreen, unoccluded window hand its buffer straight
-- to the display controller and skip a composite pass. Hyprland disables it
-- automatically the moment anything overlaps the window (a notification, a
-- layer surface), so leaving it on costs nothing when it does not apply.
hl.config({
  general = {
    allow_tearing = true,
  },
  render = {
    direct_scanout = 1,
  },
})
