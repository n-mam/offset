import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {

    required property var vr;
    property var rowHeight: 45
    property var labelWidth: 125

    Flickable {
        clip: true
        anchors.fill: parent
        anchors.margins: 15
        contentHeight: parent.height
        contentWidth: parent.width
        Column {
            spacing: 15
            anchors.fill: parent
            anchors.margins: 10
            Row {
                spacing: 4
                Text {
                    text: "Camera:"
                    color: textColor
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
                    verticalAlignment: TextInput.AlignVCenter
                    onEditingFinished: {
                        vr.name = nameTextId.text
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Source:"
                    color: textColor
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
                    verticalAlignment: TextInput.AlignVCenter
                    onEditingFinished: {
                        vr.source = sourceTextId.text
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "WaitKey:"
                    color: textColor
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
                    verticalAlignment: TextInput.AlignVCenter
                    onEditingFinished: {
                        vr.waitKeyTimeout = parseInt(timeoutTextId.text)
                    }
                }
                Text {
                    text: "ms"
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Scale:"
                    color: textColor
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: scalefTextId
                    width: 100
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("factor")
                    text: vr.scalef
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    onEditingFinished: {
                        vr.scalef = scalefTextId.text
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "BBox:"
                    color: textColor
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: bboxThicknessTextId
                    width: 120
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("thickness")
                    text: vr.bboxThickness
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    onEditingFinished: {
                        vr.bboxThickness = parseInt(bboxThicknessTextId.text)
                    }
                }
                Text {
                    text: "px"
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { width: 35 }
                Text {
                    text: "Size:"
                    color: textColor
                    width: labelWidth / 3
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: bbSizeIncrementSlider
                    width: 275
                    height: rowHeight - 10
                    from: -100
                    value: vr.bbSizeIncrement
                    to: 100
                    onMoved: {
                        vr.bbSizeIncrement = bbSizeIncrementSlider.value.toFixed(0)
                    }
                }
                Text {
                    text: bbSizeIncrementSlider.value.toFixed(0) + " px"
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Results:"
                    width: labelWidth
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Row {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    TextField {
                        id: resultsFolderId
                        width: 300
                        height: rowHeight - 10
                        placeholderText: qsTr("folder")
                        text: vr.resultsFolder
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        onEditingFinished: {
                            vr.resultsFolder = resultsFolderId.text
                        }
                    }
                    Text { width: 35 }
                    Text {
                        text: "Skip:"
                        width: labelWidth / 3
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TextField {
                        id: skipFramesId
                        width: 100
                        height: rowHeight - 10
                        placeholderText: qsTr("frames")
                        text: vr.skipFrames
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        onEditingFinished: {
                            vr.skipFrames = skipFramesId.text
                        }
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Detection:"
                    width: labelWidth
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    id: detectionGroup
                    radius: 3
                    border.width: 1
                    border.color: borderColor
                    color: "transparent"
                    implicitWidth: detectionOptions.width + 36
                    implicitHeight: rowHeight
                    Row {
                        id: detectionOptions
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        CheckBox {
                            id: detectionOptionFace
                            checked: vr.stages & 1
                            text: qsTr("Face")
                            onCheckedChanged: {
                                checked ? (vr.stages |= 1) : (vr.stages &= ~1)
                                if (checked === false && detectionOptionFaceRec.checked) {
                                    detectionOptionFaceRec.checked = false
                                }
                            }
                        }
                        CheckBox {
                            id: detectionOptionObject
                            checked: vr.stages & 2
                            text: qsTr("Object")
                            onCheckedChanged: {
                                checked ? (vr.stages |= 2) : (vr.stages &= ~2)
                            }
                        }
                        CheckBox {
                            id: detectionOptionMotion
                            checked: vr.stages & 4
                            text: qsTr("Motion")
                            onCheckedChanged: {
                                checked ? (vr.stages |= 4) : (vr.stages &= ~4)
                            }
                        }
                        CheckBox {
                            id: detectionOptionFaceRec
                            checked: vr.stages & 8
                            text: qsTr("FaceRec")
                            onCheckedChanged: {
                                checked ? (vr.stages |= 8) : (vr.stages &= ~8)
                                if (checked && detectionOptionFace.checked === false)
                                    detectionOptionFace.checked = true
                            }
                        }
                    }
                }
            }
            Row {
                visible: (vr.stages && (vr.stages !== 4)) ? true : false
                spacing: 4
                Text {
                    text: "Confidence:"
                    width: labelWidth
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    anchors.top: parent.top
                    anchors.margins: 11
                }
                Column {
                    anchors.top: parent.top
                    Row {
                        visible: detectionOptionFace.checked
                        Text {
                            text: "Face"
                            color: textColor
                            width: labelWidth / 2
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: faceConfidence
                            width: 275
                            height: rowHeight - 10
                            from: 0
                            value: vr.faceConfidence
                            to: 1
                            onMoved: {
                                vr.faceConfidence = faceConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: faceConfidence.value.toFixed(1)
                            color: textColor
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        visible: detectionOptionObject.checked
                        Text {
                            text: "Object"
                            color: textColor
                            width: labelWidth / 2
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: objectConfidence
                            width: 275
                            height: rowHeight - 10
                            from: 0
                            value: vr.objectConfidence
                            to: 1
                            onMoved: {
                                vr.objectConfidence = objectConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: objectConfidence.value.toFixed(1)
                            color: textColor
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        visible: detectionOptionFaceRec.checked
                        Text {
                            text: "FaceRec"
                            color: textColor
                            width: labelWidth / 2
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: facerecConfidence
                            width: 275
                            height: rowHeight - 10
                            from: 0
                            value: vr.facerecConfidence
                            to: 100
                            onMoved: {
                                vr.facerecConfidence = facerecConfidence.value.toFixed(1)
                            }
                        }
                        Text {
                            text: facerecConfidence.value.toFixed(1) + " (distance)"
                            color: textColor
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
            Row {
                spacing: 4
                visible: detectionOptionMotion.checked
                Text {
                    text: "Motion:"
                    color: textColor
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: areaTextId
                    width: 155
                    implicitHeight: rowHeight - 10
                    placeholderText: qsTr("exclude area")
                    text: vr.areaThreshold
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    onEditingFinished: {
                        vr.areaThreshold = parseInt(areaTextId.text)
                    }
                }
                Text {
                    text: ""
                    color: textColor
                    width: labelWidth / 3
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                RadioButton {
                    text: qsTr("MOG")
                    checked: vr.mocapAlgo === 0
                    onClicked: vr.mocapAlgo = 0
                }
                RadioButton {
                    text: qsTr("CNT")
                    checked: vr.mocapAlgo === 1
                    onClicked: vr.mocapAlgo = 1
                }
                RadioButton {
                    text: qsTr("GMG")
                    checked: vr.mocapAlgo === 2
                    onClicked: vr.mocapAlgo = 2
                }
                RadioButton {
                    text: qsTr("GSOC")
                    checked: vr.mocapAlgo === 3
                    onClicked: vr.mocapAlgo = 3
                }
                RadioButton {
                    text: qsTr("LSBP")
                    checked: vr.mocapAlgo === 4
                    onClicked: vr.mocapAlgo = 4
                }
            }
        }
    }
}
