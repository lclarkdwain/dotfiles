pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Wallust rewrites colors.json on every wallpaper change; these defaults only cover first run.
    property color bg: "#141314"
    property color fg: "#FCF7CF"
    property color accent: "#1599CA"

    // Status colours are deliberately NOT wallust-derived: the palette is wallpaper-driven, so
    // color1 is only sometimes red. A critical temperature has to read as critical every time.
    readonly property color ok: "#8CCF7E"
    readonly property color warn: "#E5B95C"
    readonly property color crit: "#E86A6A"

    readonly property color dim: Qt.rgba(
        fg.r * 0.5 + bg.r * 0.5,
        fg.g * 0.5 + bg.g * 0.5,
        fg.b * 0.5 + bg.b * 0.5,
        1)

    readonly property int radius: 14
    readonly property int pad: 11
    readonly property int gap: 7
    readonly property int cardWidth: 186
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property real surfaceAlpha: 0.82

    readonly property color surface: Qt.rgba(bg.r, bg.g, bg.b, surfaceAlpha)
    readonly property color surfaceHover: Qt.rgba(
        bg.r + (fg.r - bg.r) * 0.10,
        bg.g + (fg.g - bg.g) * 0.10,
        bg.b + (fg.b - bg.b) * 0.10,
        surfaceAlpha)

    // Warm/hot thresholds are per-metric; a 70C CPU is fine, a 70C VRM is not.
    function tempColor(v, warmAt, hotAt) {
        if (v <= 0) return root.dim;
        if (v >= hotAt) return root.crit;
        if (v >= warmAt) return root.warn;
        return root.fg;
    }

    function loadColors(text) {
        let c;
        try {
            c = JSON.parse(text);
        } catch (e) {
            return;
        }
        if (!c) return;
        if (c.background) root.bg = c.background;
        if (c.foreground) root.fg = c.foreground;
        if (c.color12) root.accent = c.color12;
    }

    FileView {
        path: Quickshell.shellPath("wallust/colors.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadColors(this.text())
    }
}
