import QtQuick
import QtQuick.Controls
import "qrc:/components"

Item {

    width: parent.width
    height: parent.height

    Column {
        
        anchors.fill: parent

        ListModel {
            id: traceModel
            ListElement {
                line: ""
            }
        }

        ListView {
            id: traceList
            clip: true
            width: parent.width
            height: parent.height * 0.90
            ScrollBar.vertical: ScrollBar {
            //width: 8
            }
            flickableDirection: Flickable.VerticalFlick
            model: traceModel
            delegate: Rectangle {
                color: Material.background
                width: ListView.view.width
                height: 17
                Label {
                    text: line
                    color: textColor
                }
            }
            Connections {
                target: logger
                enabled: (traceEnable.checkState === Qt.Checked)
                function onAddLogLine(severity, log) {
                    for (var l of log.split("\n")) {
                        traceModel.append({
                            line: new Date().toLocaleTimeString(Qt.locale(),
                            "hh:" + "mm:" + "ss:" + "zzz") + " " + l
                        })
                    }
                }
            }
        }

        Row {
            id: logActions
            spacing: 5
            width: parent.width
            height: parent.height * 0.10
            CheckBox {
                id: traceEnable
                z: 2
                checked: true
                anchors.topMargin: 3
                text: qsTr("Enable")
                anchors.verticalCenter: parent.verticalCenter
            }
            ButtonX {
                id: clearButton
                text: "Clear"
                enabled: (diskListModel.transfer === 0)
                width: 54
                height: parent.height * 0.40
                anchors.verticalCenter: parent.verticalCenter
                onButtonXClicked: traceModel.clear()
            }
            ButtonX {
                id: savebutton
                text: "Save"
                enabled: (diskListModel.transfer !== 0)
                width: 54
                height: parent.height * 0.40
                anchors.verticalCenter: parent.verticalCenter
                onButtonXClicked: {}
            }
        }

    }

    onVisibleChanged: {
        if (visible)
          traceList.positionViewAtEnd()
    }
}