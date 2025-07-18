import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {
    id: playerRoot
    property var cfg
    property var fullScreen: false
    property var controlsVisible: false
    property var defaultWidth: 0
    property var defaultHeight: 0

    implicitWidth: playerRect.width
    implicitHeight: playerRect.height

    signal cameraDeleteClickedSignal(var r)
    signal cameraSettingsClickedSignal(var r)
    signal cameraFullScreenSignal(var entering)

    Rectangle {
        id: playerRect
        width: fullScreen ? flickableGrid.width : (flickableGrid.width - 6) / 2
        height: fullScreen ? flickableGrid.height : (flickableGrid.height - 12) / 2
        border.width: 1
        color: "transparent"
        border.color: Qt.lighter(borderColor)
        VideoRenderer {
            id: vr
            cfg: playerRoot.cfg
            width: parent.width
            height: parent.height
            MouseArea {
                anchors.fill: parent
                onClicked: controlsVisible = !controlsVisible
                onDoubleClicked: {
                    fullScreen = !fullScreen
                    cameraFullScreenSignal(fullScreen)
                }
            }
        }
        Rectangle {
            z: 10
            height: 40
            opacity: 0.5
            width: parent.width - 2
            visible: controlsVisible
            color: Material.background
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            Row {
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    width: 18
                    height: 18
                    source: "qrc:/play.png"
                    MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: vr.start()
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: parent.scale = 1 + (containsMouse ? 0.2 : 0)
                    }
                }
                Image {
                    width: 18
                    height: 18
                    source: "qrc:/pause.png"
                    MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: vr.stop()
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: parent.scale = 1 + (containsMouse ? 0.2 : 0)
                    }
                }
                Image {
                    width: 18
                    height: 18
                    source: "qrc:/settings.png"
                    MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: cameraSettingsClickedSignal(vr)
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: parent.scale = 1 + (containsMouse ? 0.2 : 0)
                    }
                }

                Image {
                    width: 18
                    height: 18
                    source: "qrc:/bin.png"
                    MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: cameraDeleteClickedSignal(vr)
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: parent.scale = 1 + (containsMouse ? 0.2 : 0)
                    }
                }
            }
            Text {
                text: vr.name
                color: textColor
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 4
            }
        }
    }

    function hasVideoRenderer(r) { return r === vr }

    Component.onCompleted: {}
}
