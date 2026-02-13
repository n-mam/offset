import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls
import "qrc:/screens/Drawing.js" as Draw

Popup {
    id: root
    height: 440
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
    property string transformMode: "move"
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
            ColumnLayout {
                spacing: 4        
                ButtonGroup {
                    id: radioGroup
                }
                RadioButton {
                    text: "Move"
                    spacing: 4   // space between circle and text
                    implicitHeight: 20
                    ButtonGroup.group: radioGroup
                    checked: true  
                    onCheckedChanged: if (checked) root.transformMode = "move"
                }
                RadioButton {
                    text: "Snap"
                    spacing: 4   // space between circle and text
                    implicitHeight: 20
                    ButtonGroup.group: radioGroup
                    onCheckedChanged: if (checked) root.transformMode = "snap"
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
                    onClicked: transformRequested("up", transformMode)
                }
                // Bottom Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "↓"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    onClicked: transformRequested("down", transformMode)
                }
                // Left Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "←"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    onClicked: transformRequested("left", transformMode)
                }
                // Right Snap
                RoundButton {
                    width: 28
                    height: 28
                    text: "→"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    onClicked: transformRequested("right", transformMode)
                }
            }
            ColumnLayout {
                ToolButton {
                    text: qsTr("V")
                    onClicked: Draw.makeVertical(shape)
                    implicitHeight: 20
                }
                ToolButton {
                    text: qsTr("H")
                    onClicked: Draw.makeHorizontal(shape)
                    implicitHeight: 20
                }
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
