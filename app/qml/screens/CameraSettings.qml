import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {

    property var rowHeight: 45
    property var labelWidth: 125
    required property var vr;

    Flickable {
        clip: true
        anchors.fill: parent
        anchors.margins: 25
        contentHeight: parent.height
        contentWidth: parent.width
        Column {
            spacing: 15
            Row {
                spacing: 4
                Text {
                    text: "Camera:"
                    color: "white"
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: nameTextId
                    width: 200
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("name")
                    text: vr.name
                    onEditingFinished: {
                        vr.name = nameTextId.text
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Source:"
                    color: "white"
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: sourceTextId
                    width: 350
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("url")
                    text: vr.source
                    onEditingFinished: {
                        vr.source = sourceTextId.text
                    }
                }
            }
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
                    text: vr.scaleF
                    horizontalAlignment: TextInput.AlignHCenter
                    onEditingFinished: {
                        vr.scaleF = scalefTextId.text
                    }
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
                    id: detectionGroup
                    radius: 3
                    border.width: 1
                    border.color: borderColor
                    color: "transparent"
                    implicitWidth: detectionOptions.width + 20
                    implicitHeight: rowHeight
                    Row {
                        id: detectionOptions
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
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
                    text: "Confidence:"
                    width: labelWidth
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    anchors.top: parent.top
                    anchors.margins: 14
                }
                Column {
                    anchors.top: parent.top
                    Row {
                        Text {
                            text: "Face"
                            color: "white"
                            width: labelWidth - 25
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: faceConfidence
                            width: 275
                            height: rowHeight
                            from: 0
                            value: vr.faceConfidence
                            to: 1
                            onMoved: {
                                vr.faceConfidence = faceConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: faceConfidence.value.toFixed(1)
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        Text {
                            text: "Object"
                            color: "white"
                            width: labelWidth - 25
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: objectConfidence
                            width: 275
                            height: rowHeight
                            from: 0
                            value: vr.objectConfidence
                            to: 1
                            onMoved: {
                                vr.objectConfidence = objectConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: objectConfidence.value.toFixed(1)
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        Text {
                            text: "FaceRec"
                            color: "white"
                            width: labelWidth - 25
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: facerecConfidence
                            width: 275
                            height: rowHeight
                            from: 0
                            value: vr.facerecConfidence
                            to: 1
                            onMoved: {
                                vr.facerecConfidence = facerecConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: facerecConfidence.value.toFixed(1)
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Mocap\nexclude:"
                    color: "white"
                    width: labelWidth
                    horizontalAlignment: Text.AlignJustify
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: areaTextId
                    width: 130
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("threshold")
                    text: vr.areaThreshold
                    horizontalAlignment: TextInput.AlignHCenter
                    onEditingFinished: {
                        vr.areaThreshold = parseInt(areaTextId.text)
                    }
                }
                Text {
                    text: "area"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "BBox:"
                    color: "white"
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: bboxThicknessTextId
                    width: 130
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("thickness")
                    text: vr.bboxThickness
                    horizontalAlignment: TextInput.AlignHCenter
                    onEditingFinished: {
                        vr.bboxThickness = parseInt(bboxThicknessTextId.text)
                    }
                }
                Text {
                    text: "px"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
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
        }
    }
    Button {
        text: "Save"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
    }
}
