import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {

    property var labelWidth: 100
    property var rowHeight: 55

    Column {
        x: 20
        y: 20
        spacing: 15
        Row {
            spacing: 4
            Text {
                text: "WaitKey:"
                color: "white"
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: timeoutTextId
                width: 100
                implicitHeight: rowHeight - 10
                placeholderText: qsTr("timeout")
                text: "20"
                horizontalAlignment: TextInput.AlignHCenter
            }
            Text {
                text: "ms"
                color: "white"
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Scale:"
                color: "white"
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: scalefTextId
                width: 100
                implicitHeight: rowHeight - 10
                placeholderText: qsTr("factor")
                text: "0.35"
                horizontalAlignment: TextInput.AlignHCenter
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Detection:"
                width: labelWidth
                color: "white"
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                radius: 3
                border.width: 1
                border.color: borderColor
                color: "transparent"
                implicitWidth: detectionOptions.width
                implicitHeight: rowHeight
                Row {
                    id: detectionOptions
                    anchors.verticalCenter: parent.verticalCenter
                    RadioButton {
                        checked: true
                        text: qsTr("None")
                    }
                    RadioButton {
                        text: qsTr("Face")
                    }
                    RadioButton {
                        text: qsTr("Object")
                    }
                    RadioButton {
                        text: qsTr("Motion")
                    }
                }
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Results:"
                width: labelWidth
                color: "white"
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                radius: 3
                border.width: 1
                border.color: borderColor
                color: "transparent"
                implicitWidth: saveFolderId.width + saveCheckboxId.width + 15
                implicitHeight: rowHeight
                Row {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    CheckBox {
                        id: saveCheckboxId
                        checked: flase
                        text: qsTr("Save")
                    }
                    TextField {
                        id: saveFolderId
                        width: 300
                        height: 35
                        placeholderText: qsTr("folder")
                        text: ""
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Object\ntype:"
                color: "white"
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: objectTypeId
                implicitHeight: rowHeight
                model: ["person", "car", "dog"]
            }
        }
    }
    Button {
        text: "Save"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
