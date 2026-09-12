import QtQuick

Rectangle {
    id: root

    property string title: ""
    property string badge: ""
    property color badgeColor: Theme.dim
    property bool interactive: false
    readonly property bool hovered: mouse.containsMouse
    default property alias content: body.data

    signal activated
    signal secondaryActivated

    implicitWidth: Theme.cardWidth
    implicitHeight: layout.implicitHeight + Theme.pad * 2
    radius: Theme.radius
    color: (interactive && hovered) ? Theme.surfaceHover : Theme.surface
    border.width: 1
    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, hovered && interactive ? 0.20 : 0.09)

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    // Sibling of the content column, never inside it: anchors.fill on a Column child breaks layout.
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton) root.secondaryActivated();
            else root.activated();
        }
    }

    Column {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 6

        Item {
            width: parent.width
            height: visible ? 13 : 0
            visible: root.title.length > 0

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.letterSpacing: 1.4
                font.weight: Font.Medium
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.badge
                color: root.badgeColor
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }

        Column {
            id: body
            width: parent.width
            spacing: 4
        }
    }
}
