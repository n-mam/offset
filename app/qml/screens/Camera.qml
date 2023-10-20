import QtQuick
import QtQuick.Controls
import "qrc:/components"

StackScreen {

    id: camScreenRoot
    baseItem: baseId

    Item {
        id: baseId
        Flickable {
            id: flickableGrid
            clip: true
            width: parent.width
            height: parent.height * 0.88
            contentHeight: camGrid.height
            contentWidth: camGrid.width

            Grid {
                id: camGrid
                columns: 3
                spacing: 6
                //Player{}
            }
        }

        Row {
            id: camControl
            spacing: 10
            anchors.top: flickableGrid.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height * 0.10
            TextField {
                id: cameraUrl
                width: parent.width * 0.80
                height: parent.height * 0.80
                placeholderText: qsTr("Camera")
            }
            Button {
                width: 80
                height: parent.height * 0.80
                text: "ADD"
                onClicked: {
                if (cameraUrl.text) {
                    var component = Qt.createComponent("qrc:/components/Player.qml")
                    if (component.status == Component.Ready) {
                        finishCreation(component);
                    } else {
                        component.statusChanged.connect(finishCreation);
                    }
                }
                }
            }
        }
    }

    function finishCreation(component) {
        var object = component.createObject(camGrid, {
        "source": cameraUrl.text
        });
        cameraUrl.text = ""
        object.cameraSettingsClickedSignal.connect(cameraSettingsClicked)
        object.cameraDeleteClickedSignal.connect(cameraDeleteClicked)
    }

    function cameraSettingsClicked(vr) {
        camScreenRoot.pushComponent("qrc:/screens/CameraSettings.qml", {"vr": vr})
    }

    function cameraDeleteClicked(vr) {
        for(var i in camGrid.children) {
            if (camGrid.children[i].hasVideoRenderer(vr)) {
                camGrid.children[i].destroy()
            }
        }
    }

    Component.onCompleted: {

    }

}