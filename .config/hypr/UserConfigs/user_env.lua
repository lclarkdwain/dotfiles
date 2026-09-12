-- User environment overrides template.
-- Keep this file for personal env additions that should survive updates.

-- Examples:
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- hl.env("GDK_SCALE", "1")
-- hl.env("QT_SCALE_FACTOR", "1")

-- The caelestia QML plugin is built from the upstream clone at
-- ~/.config/quickshell/caelestia by install-caelestia.sh and installed to ~/.local,
-- which is not in Qt's default import path. Without this the shell fails with
-- 'module "Caelestia.Config" is not installed'. /usr/bin/caelestia sets nothing
-- itself, so this is the only place it comes from. Set from HOME rather than
-- hardcoded: this repo is public.
local home = os.getenv("HOME")
if home then
  local qml_dir = home .. "/.local/lib/qt6/qml"
  hl.env("QML2_IMPORT_PATH", qml_dir)
  hl.env("QML_IMPORT_PATH", qml_dir)
end
