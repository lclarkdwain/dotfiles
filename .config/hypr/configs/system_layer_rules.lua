-- System defaults migrated from configs/LayerRules.conf (auto-generated).
-- Add additional rules with apply_layer_rule({...}).
-- Example:
-- apply_layer_rule({
--   name = "My Layer Rule",
--   match = { namespace = "rofi" },
--   blur = true,
-- })

local function apply_layer_rule(rule)
  if hl.layer_rule then
    hl.layer_rule(rule)
  end
end

-- Recovered from configs/WindowRules.conf (v2.3.22 kept layerrule= lines there,
-- so the migrator found nothing in configs/LayerRules.conf, which never existed
-- in that version). Source directives, consolidated per namespace:
--   layerrule = match:namespace rofi, blur on
--   layerrule = match:namespace notifications, blur on
--   layerrule = match:namespace quickshell:overview, blur on
--   layerrule = match:namespace quickshell:overview, ignore_alpha 0.5
--   layerrule = blur on, match:namespace wallpaper
--   layerrule = animation slide, match:namespace rofi
--   layerrule = animation slide, match:namespace notifications

apply_layer_rule({
  name = "layerrule-rofi",
  match = {
    namespace = "rofi",
  },
  blur = true,
  animation = "slide",
})

apply_layer_rule({
  name = "layerrule-notifications",
  match = {
    namespace = "notifications",
  },
  blur = true,
  animation = "slide",
})

apply_layer_rule({
  name = "layerrule-quickshell-overview",
  match = {
    namespace = "quickshell:overview",
  },
  blur = true,
  ignore_alpha = 0.5,
})

apply_layer_rule({
  name = "layerrule-wallpaper",
  match = {
    namespace = "wallpaper",
  },
  blur = true,
})
