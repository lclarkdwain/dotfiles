-- Personal Hyprland config, loaded last by ~/.config/hypr/hyprland.lua.
-- ~/.config/hypr is an untouched upstream caelestia-dots copy; change things here.
-- The previous Hyprland config is kept in archive/pre-caelestia/hypr for reference.

local home = os.getenv("HOME")

------------------
---- MONITORS ----
------------------

-- Upstream picks "preferred", which drops the HDMI panel to 60 Hz. Not "highrr": it
-- trades resolution for refresh and lands on 1024x768@75.
hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

-------------
---- ENV ----
-------------

-- The caelestia QML plugin is built from the clone at ~/.config/quickshell/caelestia
-- by install-caelestia.sh into ~/.local, which is not on Qt's default import path.
-- Without this the shell fails with 'module "Caelestia.Config" is not installed'.
if home then
    local qml_dir = home .. "/.local/lib/qt6/qml"
    hl.env("QML2_IMPORT_PATH", qml_dir)
    hl.env("QML_IMPORT_PATH", qml_dir)
end

-- Upstream sets qtengine, which is not installed; qt6ct is.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

local nvidia = io.open("/proc/driver/nvidia/version", "r")
if nvidia then
    nvidia:close()
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
    hl.env("GSK_RENDERER", "ngl")
end

------------------
---- SETTINGS ----
------------------

-- Upstream disables tearing, which makes its own `immediate` game rule a no-op.
-- Upstream hardcodes "us". Rewritten by set_kb_layout in scripts/dot-scripts/prompts.sh,
-- which matches this exact line.
hl.config({ input = { kb_layout = "us" } })

hl.config({
    general = { allow_tearing = true },
    render  = { direct_scanout = 1 },
})

---------------
---- EXECS ----
---------------

hl.on("hyprland.start", function()
    -- Nothing else starts graphical-session.target, so session units (sysdiag.timer,
    -- hyprpolkitagent) never run. Chained so the target cannot race the import.
    local vars = "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE"
    hl.exec_cmd("dbus-update-activation-environment --systemd " .. vars)
    hl.exec_cmd("systemctl --user import-environment " .. vars ..
        " && systemctl --user start hyprland-session.target")
end)

------------------
---- KEYBINDS ----
------------------

-- Only chords upstream leaves unbound.
hl.bind("SUPER + Return", hl.dsp.exec_cmd("wezterm"))
hl.bind("SUPER + Space", hl.dsp.global("caelestia:launcher"))
hl.bind("SUPER + Grave", hl.dsp.global("caelestia:nexus"))
hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd(
    "wezterm start --class sysdiag-report -- sh -c '$HOME/.local/bin/sysdiag; printf \"\\npress enter to close\"; read -r _'"
))

----------------------
---- WINDOW RULES ----
----------------------

local function to_workspace(ws, matches)
    for _, match in ipairs(matches) do
        hl.window_rule({ match = match, workspace = ws })
    end
end

to_workspace("1", { { class = "^(org.wezfurlong.wezterm|kitty|Alacritty|ghostty)$" } })
to_workspace("2", {
    { class = "^(code|code-url-handler|VSCode|codium|VSCodium)$" },
    { class = "^(jetbrains-.+|dev.zed.Zed|[Cc]ursor)$" },
})
to_workspace("3", { { class = "^(zen|firefox|Firefox)$" } })
to_workspace("4", { { class = "^(chromium|google-chrome|brave-browser)$" } })
to_workspace("5", { { class = "^([Tt]hunar|org.gnome.Nautilus)$" } })
to_workspace("8", { { class = "^([Oo]bsidian)$" } })
to_workspace("9", {
    { class = "^([Ss]team)$" },
    { class = "^(com.heroicgameslauncher.hgl)$" },
    { title = "^([Ll]utris)$" },
})
to_workspace("10", {
    { class = "^(steam_app_[0-9]+|gamescope)$" },
    { class = "^(.+\\.x86_64)$" },
})

-- Upstream's game tag misses native Unity builds. Tags cannot be added from here
-- (tag definitions in rules.lua must follow every use), so set the props directly.
hl.window_rule({
    match        = { class = "^(.+\\.x86_64)$" },
    opaque       = true,
    immediate    = true,
    idle_inhibit = "always",
})

hl.window_rule({ match = { class = "^(Emulator)$" }, workspace = "2", float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "(Sign in to Steam)" }, float = true, center = true })
hl.window_rule({
    match  = { class = "^(sysdiag-report)$" },
    float  = true,
    center = true,
    size   = "(monitor_w*0.5) (monitor_h*0.6)",
})
