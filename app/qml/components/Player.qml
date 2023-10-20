import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {

    id: playerRoot

    property var source

    width: mainWindow.width - (mainWindow.width * 0.72)
    height: playerRect.height + (playerRect.height * 0.25)

    signal cameraSettingsClickedSignal(var vr)
    signal cameraDeleteClickedSignal(var vr)

    function hasVideoRenderer(vr) {
        return vr === vrid
    }

    Column {
        Rectangle {
            id: playerRect
            border.width: 1
            border.color: "white"
            color: "transparent"
            width: playerRoot.width
            height: mainWindow.height - (mainWindow.height * 0.72)

            VideoRenderer {
                id: vrid
                width: parent.width
                height: parent.height
                source: playerRoot.source
            }
        }
        Row {
            spacing: 2
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                width: 32
                height: 32
                source: "qrc:/play.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        vrid.start(["face"])
                    }
                }
            }

            Image {
                width: 32
                height: 32
                source: "qrc:/pause.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        vrid.stop()
                    }
                }
            }

            Image {
                width: 32
                height: 32
                source: "qrc:/settings.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        onClicked: cameraSettingsClickedSignal(vrid)
                    }
                }
            }

            Image {
                width: 32
                height: 32
                source: "qrc:/bin.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        onClicked: cameraDeleteClickedSignal(vrid)
                    }
                }
            }
        }
    }

}
