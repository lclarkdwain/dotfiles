import QtQuick

Canvas {
    id: root

    property var values: []
    property real maxValue: 100
    property color stroke: Theme.accent
    property int slots: 44

    // Power has no fixed ceiling, so that card scales to whatever the run has actually drawn.
    property bool autoScale: false
    property real minScale: 1

    implicitHeight: 26
    antialiasing: true

    onValuesChanged: requestPaint()
    onStrokeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const n = root.slots;
        const vals = root.values || [];
        if (vals.length < 2) return;

        const top = 2;
        const h = root.height - top * 2;
        let scale = Math.max(1, root.maxValue);
        if (root.autoScale) {
            let peak = root.minScale;
            for (let i = 0; i < vals.length; i++) peak = Math.max(peak, vals[i]);
            scale = peak * 1.15;
        }
        // A partly-filled buffer spreads across the full width; a stub at the right edge reads as broken.
        const step = root.width / Math.max(1, Math.min(n, vals.length) - 1);

        function px(i) { return i * step; }
        function py(v) { return top + h - Math.min(1, Math.max(0, v / scale)) * h; }

        ctx.beginPath();
        ctx.moveTo(px(0), py(vals[0]));
        for (let i = 1; i < vals.length; i++) ctx.lineTo(px(i), py(vals[i]));

        ctx.lineTo(px(vals.length - 1), root.height);
        ctx.lineTo(px(0), root.height);
        ctx.closePath();
        const grad = ctx.createLinearGradient(0, 0, 0, root.height);
        grad.addColorStop(0, Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.28));
        grad.addColorStop(1, Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.0));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(px(0), py(vals[0]));
        for (let i = 1; i < vals.length; i++) ctx.lineTo(px(i), py(vals[i]));
        ctx.strokeStyle = root.stroke;
        ctx.lineWidth = 1.4;
        ctx.lineJoin = "round";
        ctx.stroke();
    }
}
