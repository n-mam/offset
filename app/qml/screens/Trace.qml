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
            model: traceModel
            width: parent.width
            height: parent.height * 0.90
            ScrollBar.vertical: ScrollBar {}
            flickableDirection: Flickable.VerticalFlick
            delegate: Rectangle {
                color: Material.background
                width: ListView.view.width
                height: 17
                Label {
                    text: line
                    color: textColor
                    textFormat: Text.PlainText
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
            height: parent.height * 0.10
            anchors.horizontalCenter: parent.horizontalCenter
            ButtonX {
                id: clearButton
                width: 54
                text: "Clear"
                height: parent.height * 0.40
                onButtonXClicked: traceModel.clear()
                enabled: (diskListModel.transfer === 0)
                anchors.verticalCenter: parent.verticalCenter
            }
            ButtonX {
                id: savebutton
                width: 54
                text: "Save"
                onButtonXClicked: {}
                height: parent.height * 0.40
                enabled: (diskListModel.transfer !== 0)
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: traceEnable
                z: 2
                checked: true
                anchors.topMargin: 3
                text: qsTr("Enable")
                anchors.verticalCenter: parent.verticalCenter
            }
        }

    }
    onVisibleChanged: {
        if (visible) {
          traceList.positionViewAtEnd()
        }
    }
}