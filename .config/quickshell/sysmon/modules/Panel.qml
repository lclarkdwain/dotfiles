import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../services"

Scope {
    id: scope

    // Pinned survives window state: SUPER SHIFT D forces the panel on or off.
    property bool pinned: false
    property bool pinnedOff: false
    property var probe: null

    IpcHandler {
        target: "panel"

        function status(): string {
            const p = scope.probe;
            if (!p) return "no window";
            return JSON.stringify({
                pinned: scope.pinned,
                pinnedOff: scope.pinnedOff,
                wsId: p.ws ? p.ws.id : null,
                winCount: p.winCount,
                fullscreen: p.fullscreen,
                shouldShow: p.shouldShow,
                sampling: Sysinfo.active,
                cpu: Sysinfo.cpu,
                gpuW: Sysinfo.gpuWatts
            });
        }

        function toggle(): void {
            if (scope.pinned) {
                scope.pinned = false;
                scope.pinnedOff = true;
            } else if (scope.pinnedOff) {
                scope.pinnedOff = false;
            } else {
                scope.pinned = true;
            }
        }

        // Named pin/unpin, not show/hide: "qs ipc call panel show" is swallowed by the ipc show subcommand.
        function pin(): void {
            scope.pinned = true;
            scope.pinnedOff = false;
        }

        function unpin(): void {
            scope.pinned = false;
            scope.pinnedOff = true;
        }

        function auto(): void {
            scope.pinned = false;
            scope.pinnedOff = false;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            readonly property var hMonitor: Hyprland.monitorFor(win.screen)
            readonly property var ws: hMonitor ? hMonitor.activeWorkspace : null
            readonly property int winCount: (ws && ws.toplevels) ? ws.toplevels.values.length : 0
            readonly property bool fullscreen: ws ? ws.hasFullscreen : false
            readonly property bool shouldShow: scope.pinned || (!scope.pinnedOff && winCount === 0 && !fullscreen)

            // Animating a plain real keeps the surface alive through the fade, then drops it at zero.
            property real fade: shouldShow ? 1 : 0
            Behavior on fade {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            visible: fade > 0.001
            color: "transparent"

            WlrLayershell.namespace: "quickshell:sysmon"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: false

            anchors {
                top: true
                right: true
            }

            margins {
                top: 46
                right: 12
            }

            implicitWidth: Theme.cardWidth
            implicitHeight: stack.implicitHeight

            Component.onCompleted: {
                Sysinfo.active = Qt.binding(() => win.shouldShow);
                scope.probe = win;
            }

            function fmtRate(bps) {
                if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M/s";
                if (bps >= 1024) return Math.round(bps / 1024) + "K/s";
                return Math.round(bps) + "B/s";
            }

            function fmtWatts(w) {
                return w < 0 ? "n/a" : w.toFixed(1) + " W";
            }

            function openReport() {
                Quickshell.execDetached(["wezterm", "start", "--class", "sysdiag-report", "--",
                    "sh", "-c", Sysinfo.home + "/.local/bin/sysdiag; printf '\\npress enter to close'; read -r _"]);
            }

            Column {
                id: stack
                width: parent.width
                spacing: Theme.gap
                opacity: win.fade
                // A slight rightward drift on hide reads as the panel stepping aside.
                transform: Translate {
                    x: (1 - win.fade) * 14
                }

                Card {
                    id: healthCard

                    readonly property color statusColor: Health.status === "ok" ? Theme.ok
                        : Health.status === "warn" ? Theme.warn
                        : Health.status === "crit" ? Theme.crit
                        : Theme.dim

                    // The panel sits on the background layer, but layer surfaces still take pointer
                    // input, and this one is only ever visible on an empty workspace.
                    interactive: true
                    onActivated: win.openReport()
                    onSecondaryActivated: Health.refresh()

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: healthCard.statusColor
                            anchors.verticalCenter: parent.verticalCenter

                            // A steady dot when healthy; only a real problem pulses for attention.
                            SequentialAnimation on opacity {
                                running: Health.status === "crit"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            text: Health.status === "ok" ? "HEALTHY"
                                : Health.status === "warn" ? "ATTENTION"
                                : Health.status === "crit" ? "PROBLEMS"
                                : "CHECKING"
                            color: healthCard.statusColor
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.letterSpacing: 1.2
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        text: healthCard.hovered ? "click for report · right-click to recheck" : Health.headline
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Card {
                    title: "CPU"
                    badge: Sysinfo.fanRpm > 0 ? Sysinfo.fanRpm + " rpm" : ""

                    StatRow {
                        label: "load"
                        value: Sysinfo.cpu.toFixed(1) + "%"
                        valueSize: 15
                    }

                    Sparkline {
                        width: parent.width
                        values: Sysinfo.cpuHist
                        maxValue: 100
                        stroke: Theme.accent
                    }

                    StatRow {
                        label: "tctl"
                        value: Sysinfo.cpuTemp.toFixed(1) + "°"
                        valueColor: Theme.tempColor(Sysinfo.cpuTemp, 75, 88)
                    }

                    StatRow {
                        label: "vrm"
                        value: Sysinfo.vrmTemp.toFixed(0) + "°"
                        valueColor: Theme.tempColor(Sysinfo.vrmTemp, 65, 80)
                    }

                    StatRow {
                        label: "stall"
                        value: Sysinfo.psiCpu.toFixed(1) + "%"
                        valueColor: Sysinfo.psiCpu > 20 ? Theme.warn : Theme.fg
                    }
                }

                Card {
                    title: "GPU"
                    badge: Sysinfo.gpuMemTotalMb > 0
                        ? Math.round(Sysinfo.gpuMemUsedMb / Sysinfo.gpuMemTotalMb * 100) + "% vram"
                        : ""

                    StatRow {
                        label: "load"
                        value: Sysinfo.gpu.toFixed(0) + "%"
                        valueSize: 15
                    }

                    Sparkline {
                        width: parent.width
                        values: Sysinfo.gpuHist
                        maxValue: 100
                        stroke: Theme.ok
                    }

                    StatRow {
                        label: "temp"
                        value: Sysinfo.gpuTemp.toFixed(0) + "°"
                        valueColor: Theme.tempColor(Sysinfo.gpuTemp, 75, 85)
                    }
                }

                Card {
                    title: "POWER"
                    badge: Sysinfo.powerComplete ? "est." : "partial"
                    badgeColor: Sysinfo.powerComplete ? Theme.dim : Theme.warn

                    StatRow {
                        label: "total"
                        value: Sysinfo.totalWatts.toFixed(0) + " W"
                        valueSize: 15
                        valueColor: Theme.accent
                    }

                    Sparkline {
                        width: parent.width
                        values: Sysinfo.pwrHist
                        autoScale: true
                        minScale: 80
                        stroke: Theme.warn
                    }

                    StatRow {
                        label: "cpu"
                        value: win.fmtWatts(Sysinfo.cpuWatts)
                        valueColor: Sysinfo.cpuWatts < 0 ? Theme.dim : Theme.fg
                    }

                    StatRow {
                        label: "gpu"
                        value: win.fmtWatts(Sysinfo.gpuWatts)
                        valueColor: Sysinfo.gpuWatts < 0 ? Theme.dim : Theme.fg
                    }

                    StatRow {
                        label: "rest"
                        value: "~" + Sysinfo.baselineWatts.toFixed(0) + " W"
                        valueColor: Theme.dim
                    }
                }

                Card {
                    title: "MEMORY"

                    StatRow {
                        label: (Sysinfo.memUsedKb / 1048576).toFixed(1) + " / " + (Sysinfo.memTotalKb / 1048576).toFixed(0) + " GiB"
                        value: Sysinfo.mem.toFixed(0) + "%"
                        valueColor: Sysinfo.mem > 85 ? Theme.crit : Theme.fg
                    }

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

                        Rectangle {
                            width: parent.width * Math.min(1, Sysinfo.mem / 100)
                            height: parent.height
                            radius: parent.radius
                            color: Sysinfo.mem > 85 ? Theme.crit : Theme.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Card {
                    title: "I/O"

                    StatRow {
                        label: "net ↓"
                        value: win.fmtRate(Sysinfo.rxBps)
                    }

                    StatRow {
                        label: "net ↑"
                        value: win.fmtRate(Sysinfo.txBps)
                    }

                    StatRow {
                        label: "disk"
                        value: win.fmtRate(Sysinfo.rdBps + Sysinfo.wrBps)
                    }

                    StatRow {
                        label: "nvme"
                        value: Sysinfo.nvmeTemp.toFixed(0) + "°"
                        valueColor: Theme.tempColor(Sysinfo.nvmeTemp, 62, 72)
                    }
                }
            }
        }
    }
}
