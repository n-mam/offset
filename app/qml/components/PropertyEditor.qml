import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    height: 350
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape|Popup.CloseOnPressOutside

    property var shape
    property int shapeIndex: -1
    property int labelWidth: 85

    function showEditor(s, index) {
        shape = s
        shapeIndex = index
        open()
    }

    function feetToText(feet) {
        if (feet === undefined || isNaN(feet)) return "0'0\"";
        var f = Math.floor(feet);
        var inches = Math.round((feet - f) * 12);
        return f + "'" + inches + "\"";
    }

    function textToFeet(text) {
        // Match: optional feet and optional inches, e.g. 5'3" or 5' or 3"
        var match = text.match(/^\s*(?:(\d+)')?\s*(?:(\d+)\")?\s*$/);
        if (!match) return 0;
        var f = parseInt(match[1] || "0");
        var i = parseInt(match[2] || "0");
        return f + i/12;
    }

    ColumnLayout {
        id: mainLayout
        spacing: 5
        anchors.margins: 5
        anchors.fill: parent
        // Tighten up implicit width to fit children exactly
        implicitWidth: commonWidth + 10
        property int commonWidth: {
            var maxWidth = 0
            for(var i=0; i<children.length; i++) {
                if (children[i].implicitWidth > maxWidth)
                    maxWidth = children[i].implicitWidth
            }
            return maxWidth
        }

        RowLayout {
            spacing: 5
            Label {
                text: "Start X"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 45
                text: shape ? feetToText(shape.x1) : "0'0\""
                onEditingFinished: function() {
                    if (shape) {
                        shape.x1 = textToFeet(text)
                        canvas.requestPaint()
                    }
                }
            }
        }

        RowLayout {
            spacing: 5
            Label {
                text: "Start Y"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 45
                text: shape ? feetToText(shape.y1) : "0'0\""
                onEditingFinished: function() {
                    if (shape) {
                        shape.y1 = textToFeet(text)
                        canvas.requestPaint()
                    }
                }
            }
        }

        RowLayout {
            spacing: 5
            Label {
                text: "End X"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 45
                text: shape ? feetToText(shape.x2) : "0'0\""
                onEditingFinished: function() {
                    if (shape) {
                        shape.x2 = textToFeet(text)
                        canvas.requestPaint()
                    }
                }
            }
        }

        RowLayout {
            spacing: 5
            Label {
                text: "End Y"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 45
                text: shape ? feetToText(shape.y2) : "0'0\""
                onEditingFinished: function() {
                    if (shape) {
                        shape.y2 = textToFeet(text)
                        canvas.requestPaint()
                    }
                }
            }
        }

        Loader {
            id: shapeLoader
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
            id: wallEditorLayout
            spacing: 5
            property var shape: root.shape
            RowLayout {
                spacing: 5
                Label {
                    text: "Thickness"
                    Layout.preferredWidth: root.labelWidth
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    width: 45
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: function() {
                        if (shape) {
                            shape.thickness = textToFeet(text)
                            canvas.requestPaint()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: doorEditor
        ColumnLayout {
            id: doorEditorLayout
            spacing: 5
            property var shape: root.shape
            RowLayout {
                spacing: 5
                Label {
                    text: "Thickness"
                    Layout.preferredWidth: root.labelWidth
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    width: 45
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: function() {
                        if (shape) {
                            shape.thickness = textToFeet(text)
                            canvas.requestPaint()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: windowEditor
        ColumnLayout {
            id: windowEditorLayout
            spacing: 5
            property var shape: root.shape
            RowLayout {
                spacing: 5
                Label {
                    text: "Thickness"
                    Layout.preferredWidth: root.labelWidth
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    width: 45
                    text: shape ? feetToText(shape.thickness) : "0'6\""
                    onEditingFinished: function() {
                        if (shape) {
                            shape.thickness = textToFeet(text)
                            canvas.requestPaint()
                        }
                    }
                }
            }
        }
    }
}
