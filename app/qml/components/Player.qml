import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {
    id: playerRoot
    property var cfg
    property var increment: 0
    property var controlsVisible: false

    implicitWidth: playerRect.width
    implicitHeight: playerRect.height

    signal cameraDeleteClickedSignal(var r)
    signal cameraSettingsClickedSignal(var r)

    Rectangle {
        id: playerRect
        border.width: 1
        color: "transparent"
        border.color: borderColor
        width: mainWindow.width - (mainWindow.width * 0.60) + playerRoot.increment - 40 - ( 2 * appSpacing) -10
        height: mainWindow.height - (mainWindow.height * 0.60) + (playerRoot.increment * (mainWindow.height/mainWindow.width))

        Column {
            spacing: appSpacing
            anchors.fill: parent
            Row {
                z: 10
                spacing: 0
                anchors.margins: 4
                anchors.top: parent.top
                visible: controlsVisible
                anchors.left: parent.left
                Slider {
                    id: zoomSlider
                    to: 450
                    value: 0
                    width: 220
                    height: 20
                    from: -450
                    onMoved: playerRoot.increment = zoomSlider.value
                }
            }
            VideoRenderer {
                id: vr
                cfg: playerRoot.cfg
                width: parent.width
                height: parent.height
                MouseArea {
                    anchors.fill: parent
                    onClicked: controlsVisible = !controlsVisible;
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
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
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
    }

    function hasVideoRenderer(r) { return r === vr }

    Component.onCompleted: {}
}
