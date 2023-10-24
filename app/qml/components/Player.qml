import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {

    id: playerRoot

    property var cfg
    property var increment: 0
    property var controlsVisible: false

    width: playerRect.width
    height: playerRect.height

    signal cameraSettingsClickedSignal(var r)
    signal cameraDeleteClickedSignal(var r)

    function hasVideoRenderer(r) {
        return r === vr
    }

    Column {
        spacing: 5

        Rectangle {
            id: playerRect
            border.width: 1
            border.color: controlsVisible ? "steelblue" : "white"
            color: "transparent"
            width: mainWindow.width - (mainWindow.width * 0.60) + playerRoot.increment
            height: mainWindow.height - (mainWindow.height * 0.60) + (playerRoot.increment * (mainWindow.height/mainWindow.width))

            Row {
                z: 10
                spacing: 0
                visible: controlsVisible
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 4

                Slider {
                    id: playerZoomSlider
                    width: 220
                    height: 20
                    from: -450
                    value: 0
                    to: 450
                    onMoved: playerRoot.increment = playerZoomSlider.value
                }
                Text {
                    text: "  "
                }
                Text {
                    text: vr.name
                    color: "white"
                }
            }

            VideoRenderer {
                id: vr
                width: parent.width
                height: parent.height
                cfg: playerRoot.cfg
            }

            Row {
                z: 10
                spacing: 12
                visible: controlsVisible
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 4
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

            MouseArea {
                anchors.fill: parent
                onClicked: controlsVisible = !controlsVisible;
            }
        }
    }

    Component.onCompleted: {

    }
}
