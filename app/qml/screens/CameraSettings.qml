import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {

    property var rowHeight: 55
    property var labelWidth: 100
    required property var vr;

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
                text: vr.waitKeyTimeout
                horizontalAlignment: TextInput.AlignHCenter
                onEditingFinished: {
                    vr.waitKeyTimeout = parseInt(timeoutTextId.text)
                }
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
                text: "0.5"
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
                    CheckBox {
                        checked: vr.pipelineStages & 1
                        text: qsTr("Face")
                        onCheckedChanged: {
                            checked ? (vr.pipelineStages |= 1) : (vr.pipelineStages &= ~1)
                        }
                    }
                    CheckBox {
                        checked: vr.pipelineStages & 2
                        text: qsTr("Object")
                        onCheckedChanged: {
                            checked ? (vr.pipelineStages |= 2) : (vr.pipelineStages &= ~2)
                        }
                    }
                    CheckBox {
                        checked: vr.pipelineStages & 4
                        text: qsTr("Motion")
                        onCheckedChanged: {
                            checked ? (vr.pipelineStages |= 4) : (vr.pipelineStages &= ~4)
                        }
                    }
                    CheckBox {
                        checked: vr.pipelineStages & 8
                        text: qsTr("FaceRec")
                        onCheckedChanged: {
                            checked ? (vr.pipelineStages |= 8) : (vr.pipelineStages &= ~8)
                        }
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
            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                CheckBox {
                    id: saveCheckboxId
                    checked: false
                    text: qsTr("Save")
                }
                TextField {
                    id: saveFolderId
                    width: 300
                    height: rowHeight
                    placeholderText: qsTr("folder")
                    text: ""
                    anchors.verticalCenter: parent.verticalCenter
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
