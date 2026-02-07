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
    property int labelWidth: 70

    function showEditor(s, index) {
        shape = s
        shapeIndex = index
        open()
    }

    ColumnLayout {
        id: mainLayout
        spacing: 6
        anchors.margins: 5
        anchors.fill: parent
        // Tighten up implicit width to fit children exactly
        implicitWidth: commonWidth + 5
        // For convenience, calculate max width needed by rows
        property int commonWidth: {
            var maxWidth = 0
            for(var i=0; i<children.length; i++) {
                if (children[i].implicitWidth > maxWidth)
                    maxWidth = children[i].implicitWidth
            }
            return maxWidth
        }

        RowLayout {
            spacing: 8
            Label {
                text: "Start X"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 70
                text: shape && shape.x1 !== undefined ? shape.x1.toFixed(2) : "0"
                validator: DoubleValidator {}
                onEditingFinished: if (shape) shape.x1 = parseFloat(text)
            }
        }

        RowLayout {
            spacing: 8
            Label {
                text: "Start Y"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 70
                text: shape && shape.y1 !== undefined ? shape.y1.toFixed(2) : "0"
                validator: DoubleValidator {}
                onEditingFinished: if (shape) shape.y1 = parseFloat(text)
            }
        }

        RowLayout {
            spacing: 8
            Label {
                text: "End X"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 70
                text: shape && shape.x2 !== undefined ? shape.x2.toFixed(2) : "0"
                validator: DoubleValidator {}
                onEditingFinished: if (shape) shape.x2 = parseFloat(text)
            }
        }

        RowLayout {
            spacing: 8
            Label {
                text: "End Y"
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignVCenter
            }
            TextField {
                width: 70
                text: shape && shape.y2 !== undefined ? shape.y2.toFixed(2) : "0"
                validator: DoubleValidator {}
                onEditingFinished: if (shape) shape.y2 = parseFloat(text)
            }
        }

        Loader {
            id: wallLoader
            sourceComponent: {
                if (!shape)
                    return undefined
                if (shape.type === "wall")
                    return wallEditor
                return undefined
            }
        }
    }

    // Wall editor component
    Component {
        id: wallEditor
        ColumnLayout {
            id: wallEditorLayout
            spacing: 6
            property var shape: root.shape
            RowLayout {
                spacing: 8
                Label {
                    text: "Thickness"
                    Layout.preferredWidth: root.labelWidth
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    width: 70
                    text: shape && shape.thickness !== undefined
                          ? shape.thickness.toFixed(2)
                          : "0.50"
                    validator: DoubleValidator { bottom: 0 }
                    onEditingFinished: if (shape)
                        shape.thickness = parseFloat(text)
                }
            }
        }
    }
}
