pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string status: "unknown"
    property int issueCount: 0
    property string headline: "checking…"

    readonly property string home: Quickshell.env("HOME")

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    Process {
        id: proc
        command: [root.home + "/.local/bin/sysdiag", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let r;
                try {
                    r = JSON.parse(this.text);
                } catch (e) {
                    root.status = "unknown";
                    root.headline = "check failed";
                    return;
                }
                root.status = r.status || "unknown";

                const bad = (r.checks || []).filter(c => c.severity !== "ok");
                root.issueCount = bad.length;
                if (bad.length === 0) root.headline = "all clear";
                else if (bad.length === 1) root.headline = bad[0].summary;
                else root.headline = bad.length + " items need attention";
            }
        }
    }

    // sysdiag shells out to journalctl and pacman, so it runs rarely rather than on every tick.
    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
