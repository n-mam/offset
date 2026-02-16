import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import "qrc:/screens/Shape.js" as Shape
import "qrc:/screens/Drawing.js" as Draw

Popup {
    id: root
    height: 600
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape|Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#2f3234"
        opacity: 0.65
        radius: 6
    }

    property var shape
    property int shapeIndex: -1
    property int labelWidth: 85
    property string snapGrid: "major"
    property string anchorPoint: "C"
    signal transformRequested(string direction, string mode)

    ColorDialog {
        id: colorDialog
        title: "Select Color"
        onAccepted: {
            if (root.shape) {
                root.shape.color = selectedColor.toString()
                canvas.requestPaint()
            }
        }
    }

    function showEditor(s, index) {
        shape = s
        shapeIndex = index
        open()
    }

    function feetToText(feet) {
        if (!Number.isFinite(feet))
            return "0'0\""
        const sign = feet < 0 ? "-" : ""
        const abs = Math.abs(feet)
        const f = Math.floor(abs)
        const inches = Math.round((abs - f) * 12)
        return sign + f + "'" + inches + "\""
    }

    function textToFeet(text) {
        // Supports: -5'3", -5', -3", 5'6"
        const match = text.match(
            /^\s*(-)?\s*(?:(\d+)')?\s*(?:(\d+)\")?\s*$/
        )
        if (!match) return NaN
        const sign = match[1] ? -1 : 1
        const f = parseInt(match[2] || "0")
        const i = parseInt(match[3] || "0")
        return sign * (f + i / 12)
    }

    function assignIfValid(prop, text) {
        if (!shape) return
        const v = textToFeet(text)
        if (Number.isFinite(v)) {
            shape[prop] = v
            canvas.requestPaint()
        }
    }

    ColumnLayout {
        spacing: 5
        anchors.margins: 5
        anchors.fill: parent

        RowLayout {
            Label { text: "Start X"; Layout.preferredWidth: root.labelWidth }
            TextField {
                Layout.preferredWidth:  80
                Layout.preferredHeight:  40
                text: shape ? feetToText(shape.x1) : "0'0\""
                onEditingFinished: assignIfValid("x1", text)
            }
        }

        RowLayout {
            Label { text: "Start Y"; Layout.preferredWidth: root.labelWidth }
            TextField {
                Layout.preferredWidth:  80
                Layout.preferredHeight:  40
                text: shape ? feetToText(shape.y1) : "0'0\""
                onEditingFinished: assignIfValid("y1", text)
            }
        }

        RowLayout {
            Label { text: "End X"; Layout.preferredWidth: root.labelWidth }
            TextField {
                Layout.preferredWidth:  80
                Layout.preferredHeight:  40
                text: shape ? feetToText(shape.x2) : "0'0\""
                onEditingFinished: assignIfValid("x2", text)
            }
        }

        RowLayout {
            Label { text: "End Y"; Layout.preferredWidth: root.labelWidth }
            TextField {
                Layout.preferredWidth:  80
                Layout.preferredHeight:  40
                text: shape ? feetToText(shape.y2) : "0'0\""
                onEditingFinished: assignIfValid("y2", text)
            }
        }

        Loader {
            sourceComponent: {
                if (!shape) return undefined
                if (shape.type === "wall") return wallEditor
                if (shape.type === "door") return doorEditor
                if (shape.type === "window") return windowEditor
                return undefined
            }
        }

        RowLayout {
            Label { text: "Color"; Layout.preferredWidth: root.labelWidth }
            Rectangle {
                width: 60
                height: 30
                radius: 3
                border.color: "#888"
                border.width: 1
                color: shape && shape.color ? shape.color : "#ffffff"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!shape) return
                        colorDialog.selectedColor = Qt.color(shape.color || "#ffffff")
                        colorDialog.open()
                    }
                }
            }
        }

        RowLayout {
            Label { text: "Snap"; Layout.preferredWidth: root.labelWidth }
            ColumnLayout {
                spacing: 4
                ButtonGroup { id: snapModeGroup }
                RadioButton {
                    id: majorRadio
                    checked: true
                    ButtonGroup.group: snapModeGroup
                    padding: 0
                    spacing: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    implicitHeight: 18
                    implicitWidth: contentItem.implicitWidth
                    onCheckedChanged: if (checked) root.snapGrid = "major"
                    contentItem: Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 14
                            height: 14
                            radius: width / 2
                            color: "#585858"
                            border.width: 1
                            border.color: "white"
                            Rectangle {
                                anchors.centerIn: parent
                                width: majorRadio.checked ? 8 : 0
                                height: width
                                radius: width / 2
                                color: "white"
                                Behavior on width {
                                    NumberAnimation { duration: 120 }
                                }
                            }
                        }
                        Text {
                            text: "Major"
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    indicator: Item {}
                }

                RadioButton {
                    id: minorRadio
                    ButtonGroup.group: snapModeGroup
                    padding: 0
                    spacing: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    implicitHeight: 18
                    implicitWidth: contentItem.implicitWidth
                    onCheckedChanged: if (checked) root.snapGrid = "minor"
                    contentItem: Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 14
                            height: 14
                            radius: width / 2
                            color: "#585858"
                            border.width: 1
                            border.color: "white"
                            Rectangle {
                                anchors.centerIn: parent
                                width: minorRadio.checked ? 8 : 0
                                height: width
                                radius: width / 2
                                color: "white"
                                Behavior on width {
                                    NumberAnimation { duration: 120 }
                                }
                            }
                        }
                        Text {
                            text: "Minor"
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    indicator: Item {}
                }
            }

            Item {
                id: snapControl
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: "#666"
                    border.width: 1
                }
                // Top Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "↑"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    onClicked: transformRequested("up", snapGrid)
                }
                // Bottom Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "↓"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    onClicked: transformRequested("down", snapGrid)
                }
                // Left Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "←"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    onClicked: transformRequested("left", snapGrid)
                }
                // Right Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "→"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    onClicked: transformRequested("right", snapGrid)
                }
            }
        }

        RowLayout {
            Label { text: "Flip"; Layout.preferredWidth: root.labelWidth * 0.70 }
            ToolButton {
                icon.source: "qrc:/flip-h.png"
                icon.width: 24
                icon.height: 24
                display: AbstractButton.IconOnly
                onClicked: Shape.flip(shape, true)
                implicitHeight: 30
                implicitWidth: 50
                background: Rectangle {
                    radius: 4
                    color: "#656565"
                    border.color: "#555"
                }
            }
            ToolButton {
                icon.source: "qrc:/flip-v.png"
                icon.width: 24
                icon.height: 24
                display: AbstractButton.IconOnly
                onClicked: Shape.flip(shape, false)
                implicitHeight: 30
                implicitWidth: 50
                background: Rectangle {
                    radius: 4
                    color: "#656565"
                    border.color: "#555"
                }
            }
        }

        Rectangle {
            // Set width to fill its parent and height to 1 pixel
            Layout.fillWidth: true
            width: parent.width
            height: 2
            color: "#a5a5a5" // A light gray color
            // Optional: Add margins using anchors or Layout.margins
        }

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter
            ButtonGroup { id: anchorPointGroup }
            Repeater {
                model: [
                    { color: "green", value: "S" },
                    { color: "blue",  value: "C" },
                    { color: "red",   value: "E" }
                ]
                delegate: RadioButton {
                    id: radio
                    checked: modelData.value === "C"
                    ButtonGroup.group: anchorPointGroup
                    padding: 0
                    spacing: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    // IMPORTANT: fixed size so layout never changes
                    implicitWidth: 18
                    implicitHeight: 18
                    onCheckedChanged: {
                        if (checked) root.anchorPoint = modelData.value
                    }
                    contentItem: Item {
                        anchors.fill: parent
                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: modelData.color
                            border.width: 1
                            border.color: "white"
                            // animated inner ring
                            Rectangle {
                                anchors.centerIn: parent
                                width: radio.checked ? 10 : 0
                                height: width
                                radius: width / 2
                                color: "white"
                                Behavior on width {
                                    NumberAnimation { duration: 120 }
                                }
                            }
                        }
                    }
                    indicator: Item {}
                }
            }
        }

        RowLayout {
            Label { text: "Align"; Layout.preferredWidth: root.labelWidth * 0.7 }
            ToolButton {
                text: qsTr("H")
                onClicked: Draw.makeHorizontal(shape, root.anchorPoint)
                implicitHeight: 30
                implicitWidth: 50
                background: Rectangle {
                    radius: 4
                    color: "#656565"
                    border.color: "#555"
                }
            }
            ToolButton {
                text: qsTr("V")
                onClicked: Draw.makeVertical(shape, root.anchorPoint)
                implicitHeight: 30
                implicitWidth: 50
                background: Rectangle {
                    radius: 4
                    color: "#656565"
                    border.color: "#555"
                }
            }
        }

        RowLayout {
            Label { text: "Length"; Layout.preferredWidth: root.labelWidth * 0.75 }
            TextField {
                Layout.preferredWidth: 80
                Layout.preferredHeight:  40
                text: shape ? feetToText(
                    Math.hypot(shape.x2 - shape.x1, shape.y2 - shape.y1)) : "0'0\""
                onEditingFinished: Draw.changeLength(shape, textToFeet(text), root.anchorPoint)
            }
        }
    }

    Component {
        id: wallEditor
        ColumnLayout {
            RowLayout {
                Label { text: "Thickness"; Layout.preferredWidth: root.labelWidth }
                TextField {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight:  40
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: assignIfValid("thickness", text)
                }
            }
        }
    }

    Component {
        id: doorEditor
        ColumnLayout {
            RowLayout {
                Label { text: "Thickness"; Layout.preferredWidth: root.labelWidth }
                TextField {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight:  40
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: assignIfValid("thickness", text)
                }
            }
        }
    }

    Component {
        id: windowEditor
        ColumnLayout {
            RowLayout {
                Label { text: "Thickness"; Layout.preferredWidth: root.labelWidth }
                TextField {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight:  40
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: assignIfValid("thickness", text)
                }
            }
        }
    }
}
