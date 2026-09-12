import QtQuick

Item {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.fg
    property int valueSize: 12

    width: parent ? parent.width : 0
    implicitHeight: Math.max(lbl.implicitHeight, val.implicitHeight)

    Text {
        id: lbl
        anchors.left: parent.left
        anchors.baseline: val.baseline
        text: root.label
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
    }

    Text {
        id: val
        anchors.right: parent.right
        text: root.value
        color: root.valueColor
        font.family: Theme.fontFamily
        font.pixelSize: root.valueSize
        font.weight: Font.Medium
    }
}
