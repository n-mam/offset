import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {

    id: playerRoot

    property var cfg

    width: mainWindow.width - (mainWindow.width * 0.72)
    height: playerRect.height + (playerRect.height * 0.25)

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
            border.color: "white"
            color: "transparent"
            width: playerRoot.width
            height: mainWindow.height - (mainWindow.height * 0.70)

            VideoRenderer {
                id: vr
                width: parent.width
                height: parent.height
                name: playerRoot.cfg.name
                source: playerRoot.cfg.source
                waitKeyTimeout: playerRoot.cfg.waitKeyTimeout
                pipelineStages: playerRoot.cfg.stages
            }
        }
        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                width: 18
                height: 18
                source: "qrc:/play.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        vr.start()
                    }
                }
            }

            Image {
                width: 18
                height: 18
                source: "qrc:/pause.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        vr.stop()
                    }
                }
            }

            Image {
                width: 18
                height: 18
                source: "qrc:/settings.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        onClicked: cameraSettingsClickedSignal(vr)
                    }
                }
            }

            Image {
                width: 18
                height: 18
                source: "qrc:/bin.png"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        onClicked: cameraDeleteClickedSignal(vr)
                    }
                }
            }
        }
    }

}
