import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {

    id: playerRoot

    property var cfg
    property var increment: 0

    width: playerRect.width
    height:  20 + playerRect.height + 20

    signal cameraSettingsClickedSignal(var r)
    signal cameraDeleteClickedSignal(var r)

    function hasVideoRenderer(r) {
        return r === vr
    }

    Column {
        spacing: 5
        Row {
            spacing: 0
            Image {
                width: 18
                height: 18
                source: "qrc:/zoom-out.png"
            }
            Slider {
                id: playerZoomSlider
                width: 236
                height: 20
                from: -450
                value: 0
                to: 450
                onMoved: {
                    playerRoot.increment = playerZoomSlider.value
                }
            }
            Image {
                width: 18
                height: 18
                source: "qrc:/zoom.png"
            }
        }
        Rectangle {
            id: playerRect
            border.width: 1
            border.color: "white"
            color: "transparent"
            width: mainWindow.width - (mainWindow.width * 0.72) + playerRoot.increment
            height: mainWindow.height - (mainWindow.height * 0.72) + (playerRoot.increment * (mainWindow.height/mainWindow.width))

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
            spacing: 12
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
