import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    height: 350
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
                width: 60
                text: shape ? feetToText(shape.x1) : "0'0\""
                onEditingFinished: assignIfValid("x1", text)
            }
        }

        RowLayout {
            Label { text: "Start Y"; Layout.preferredWidth: root.labelWidth }
            TextField {
                width: 60
                text: shape ? feetToText(shape.y1) : "0'0\""
                onEditingFinished: assignIfValid("y1", text)
            }
        }

        RowLayout {
            Label { text: "End X"; Layout.preferredWidth: root.labelWidth }
            TextField {
                width: 60
                text: shape ? feetToText(shape.x2) : "0'0\""
                onEditingFinished: assignIfValid("x2", text)
            }
        }

        RowLayout {
            Label { text: "End Y"; Layout.preferredWidth: root.labelWidth }
            TextField {
                width: 60
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
    }

    Component {
        id: wallEditor
        ColumnLayout {
            RowLayout {
                Label { text: "Thickness"; Layout.preferredWidth: root.labelWidth }
                TextField {
                    width: 60
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
                    width: 60
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
                    width: 60
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: assignIfValid("thickness", text)
                }
            }
        }
    }
}
