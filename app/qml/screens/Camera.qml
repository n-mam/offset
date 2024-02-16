import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls
import "qrc:/components"

StackScreen {
    id: cameraRoot
    baseItem: baseId
    Item {
        id: baseId
        Flickable {
            id: flickableGrid
            clip: true
            anchors.margins: 4
            anchors.left: baseId.left
            anchors.right: baseId.right
            contentWidth: camGrid.width
            contentHeight: camGrid.height
            height: cameraRoot.height * 0.90
            flickableDirection: Flickable.VerticalFlick
            Grid {
                id: camGrid
                columns: 2
                spacing: 8
                //Player{}
            }
        }
        Row {
            id: camControl
            spacing: 10
            anchors.bottom: baseId.bottom
            width: cameraUrl.width + 75 + 100
            anchors.horizontalCenter: parent.horizontalCenter
            TextField {
                id: cameraUrl
                width: 275
                height: textFieldHeight
                font.pointSize: pointSize
                placeholderText: qsTr("Camera source")
                verticalAlignment: TextInput.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            ButtonX {
                width: 75
                height: textFieldHeight
                text: "Add"
                anchors.verticalCenter: parent.verticalCenter
                onButtonXClicked: {
                    if (cameraUrl.text) {
                        createPlayerObject({
                            "cfg": {
                                "source": cameraUrl.text,
                                "stages": 0
                            }})
                        cameraUrl.text = ""
                    }
                }
            }
            ButtonX {
                width: 100
                height: textFieldHeight
                text: "Import"
                onButtonXClicked: importCameraCfgDialog.open()
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        FileDialog {
            id: importCameraCfgDialog
            title: "Please choose the camera config file"
            onAccepted: {
                var path = importCameraCfgDialog.selectedFiles.toString();
                path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
                var camera_cfgs = appConfig.readCameraConfiguration(
                    decodeURIComponent(path).replace(/\//g, "/"))
                var cfgs = JSON.parse(camera_cfgs);
                for (var i in cfgs) {
                    createPlayerObject({"cfg": cfgs[i]})
                }
            }
            onRejected: {
                console.log("Canceled")
            }
        }
    }
    function createPlayerObject(cfg) {
        var component = Qt.createComponent("qrc:/components/Player.qml")
        //console.log(component.errorString())
        if (component.status == Component.Ready) {
            finishCreation(component, cfg);
        } else {
            component.statusChanged.connect(()=>{
                finishCreation(component, cfg)
            });
        }
    }
    function finishCreation(component, cfg) {
        var object = component.createObject(camGrid, cfg);
        object.cameraSettingsClickedSignal.connect(cameraSettingsClicked)
        object.cameraDeleteClickedSignal.connect(cameraDeleteClicked)
    }
    function cameraSettingsClicked(vr) {
        cameraRoot.pushComponent("qrc:/screens/CameraSettings.qml", {"vr": vr})
    }
    function cameraDeleteClicked(vr) {
        for(var i in camGrid.children) {
            if (camGrid.children[i].hasVideoRenderer(vr)) {
                camGrid.children[i].destroy()
            }
        }
    }
    Component.onCompleted: {}
}