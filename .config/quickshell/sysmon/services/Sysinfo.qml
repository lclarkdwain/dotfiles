pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Everything here is gated on this: a monitor widget must never cost a frame in a game.
    property bool active: false

    property real cpu: 0
    property real mem: 0
    property real memUsedKb: 0
    property real memTotalKb: 1
    property real cpuTemp: 0
    property real vrmTemp: 0
    property real nvmeTemp: 0
    property int fanRpm: 0
    property real psiCpu: 0
    property real rxBps: 0
    property real txBps: 0
    property real rdBps: 0
    property real wrBps: 0

    // -1 means the counter is unreadable; the panel shows "n/a" rather than a fake zero.
    property real cpuWatts: -1

    property real gpu: 0
    property real gpuTemp: 0
    property real gpuWatts: -1
    property real gpuMemUsedMb: 0
    property real gpuMemTotalMb: 0

    // Board, drives and fans cannot be measured without a wall meter, so they are a flat estimate.
    property real baselineWatts: 35
    readonly property real totalWatts: (cpuWatts >= 0 ? cpuWatts : 0) + (gpuWatts >= 0 ? gpuWatts : 0) + baselineWatts
    readonly property bool powerComplete: cpuWatts >= 0 && gpuWatts >= 0

    readonly property int histLen: 44
    property var cpuHist: []
    property var gpuHist: []
    property var pwrHist: []

    readonly property string home: Quickshell.env("HOME")

    function pushHist(arr, v) {
        const a = arr.slice();
        a.push(v);
        while (a.length > root.histLen) a.shift();
        return a;
    }

    function num(v) {
        return (v === null || v === undefined || isNaN(v)) ? 0 : v;
    }

    onActiveChanged: {
        if (!active) return;
        gpuInfo.running = true;
    }

    Process {
        id: sampler
        running: root.active
        command: [root.home + "/.local/bin/sysmon-sample", "-i", "2"]
        stdout: SplitParser {
            onRead: data => {
                let s;
                try {
                    s = JSON.parse(data);
                } catch (e) {
                    return;
                }
                root.cpu = root.num(s.cpu);
                root.mem = root.num(s.mem);
                root.memUsedKb = root.num(s.mem_used_kb);
                root.memTotalKb = Math.max(1, root.num(s.mem_total_kb));
                root.cpuTemp = root.num(s.cpu_tctl);
                root.vrmTemp = root.num(s.vrm);
                root.nvmeTemp = root.num(s.nvme);
                root.fanRpm = root.num(s.fan_rpm);
                root.psiCpu = root.num(s.psi_cpu);
                root.rxBps = root.num(s.rx_bps);
                root.txBps = root.num(s.tx_bps);
                root.rdBps = root.num(s.rd_bps);
                root.wrBps = root.num(s.wr_bps);
                root.cpuWatts = (s.cpu_w === null || s.cpu_w === undefined) ? -1 : s.cpu_w;

                root.cpuHist = root.pushHist(root.cpuHist, root.cpu);
                root.pwrHist = root.pushHist(root.pwrHist, root.totalWatts);
            }
        }
    }

    // One-shot: dmon reports VRAM used but never the total.
    Process {
        id: gpuInfo
        command: ["nvidia-smi", "--query-gpu=memory.total", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                const v = parseFloat(data.trim());
                if (!isNaN(v)) root.gpuMemTotalMb = v;
            }
        }
    }

    // One long-lived stream beats respawning nvidia-smi every tick.
    Process {
        id: gpuMon
        running: root.active
        command: ["nvidia-smi", "dmon", "-s", "pucm", "-d", "2"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.length === 0 || line[0] === "#") return;
                const f = line.split(/\s+/);
                if (f.length < 13) return;
                const pwr = parseFloat(f[1]);
                const temp = parseFloat(f[2]);
                const sm = parseFloat(f[4]);
                const fb = parseFloat(f[12]);
                if (!isNaN(pwr)) root.gpuWatts = pwr;
                if (!isNaN(temp)) root.gpuTemp = temp;
                if (!isNaN(sm)) {
                    root.gpu = sm;
                    root.gpuHist = root.pushHist(root.gpuHist, sm);
                }
                if (!isNaN(fb)) root.gpuMemUsedMb = fb;
            }
        }
    }
}
