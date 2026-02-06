import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 280
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var shape
    property int shapeIndex: -1

    // Function to show the editor
    function showEditor(s, index) {
        shape = s
        shapeIndex = index
        root.open()   // call Popup.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Common shape properties
        ColumnLayout {
            id: commonProperties
            property var shape: root.shape
            spacing: 6

            RowLayout {
                spacing: 6
                Label { 
                    text: "Start X"
                    Layout.alignment: Qt.AlignVCenter
                }
                SpinBox {
                    value: shape ? shape.x1 : 0
                    stepSize: 1
                    Layout.fillWidth: true
                    onValueModified: if(shape) shape.x1 = value
                }
            }

            RowLayout {
                spacing: 6
                Label { 
                    text: "Start Y"
                    Layout.alignment: Qt.AlignVCenter
                }
                SpinBox {
                    value: shape ? shape.y1 : 0
                    stepSize: 1
                    Layout.fillWidth: true
                    onValueModified: if(shape) shape.y1 = value
                }
            }

            RowLayout {
                spacing: 6
                Label { 
                    text: "End X"
                    Layout.alignment: Qt.AlignVCenter
                }
                SpinBox {
                    value: shape ? shape.x2 : 0
                    stepSize: 1
                    Layout.fillWidth: true
                    onValueModified: if(shape) shape.x2 = value
                }
            }

            RowLayout {
                spacing: 6
                Label { 
                    text: "End Y"
                    Layout.alignment: Qt.AlignVCenter
                }
                SpinBox {
                    value: shape ? shape.y2 : 0
                    stepSize: 1
                    Layout.fillWidth: true
                    onValueModified: if(shape) shape.y2 = value
                }
            }
        }

        // Loader for type-specific properties
        Loader {
            sourceComponent: {
                if (!shape) return null
                switch (shape.type) {
                case "wall": return wallEditor
                // Extendable for other types:
                // case "door": return doorEditor
                // case "window": return windowEditor
                // case "dimension": return dimensionEditor
                }
                return null
            }
        }
    }

    // Wall-specific properties
    Component {
        id: wallEditor
        ColumnLayout {
            property var shape: root.shape
            spacing: 6

            RowLayout {
                spacing: 6
                Label { 
                    text: "Thickness (ft)"
                    Layout.alignment: Qt.AlignVCenter
                }
                SpinBox {
                    value: shape && shape.thickness !== undefined ? shape.thickness : 0.5
                    stepSize: 1
                    Layout.fillWidth: true
                    onValueModified: if(shape) shape.thickness = value
                }
            }
        }
    }

    // Future components can be added here
    // Component { id: doorEditor; ... }
    // Component { id: windowEditor; ... }
    // Component { id: dimensionEditor; ... }
}
