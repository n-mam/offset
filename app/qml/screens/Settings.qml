import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {

    property var context
    property var rowHeight: 45
    property var labelWidth: 130

    Row {
        anchors.right: parent.right
        Rectangle {
            id: testRect
            width: 200
            height: 100
            radius: 3
            border.width: 1
            border.color: borderColor
            color: "transparent"
            Text {
                color: textColor
                text: "this is a test rectangle"
                anchors.centerIn: parent
            }
        }
        Rectangle {
            id: testRect2
            width: 100
            height: 100
            radius: 3
            border.width: 1
            border.color: borderColor
            color: elementDiffFullColor
            Text {
                color: textColor
                text: "Test"
                anchors.centerIn: parent
            }
        }
    }

    Column {
        spacing: 15
        anchors.fill: parent
        anchors.margins: 10
        Row {
            spacing: 4
            Text {
                text: "Border:"
                color: textColor
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: borderColorId
                width: 100
                height: rowHeight - 10
                placeholderText: qsTr("color")
                text: borderColor
                onPressed: {
                    context = "border"
                    colorDialog.open()
                }
                onEditingFinished: {
                    borderColor = borderColorId.text
                }
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Text:"
                color: textColor
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: textColorId
                width: 100
                height: rowHeight - 10
                placeholderText: qsTr("color")
                text: textColor
                onPressed: {
                    context = "text"
                    colorDialog.open()
                }
                onEditingFinished: {
                    textColor = textColorId.text
                }
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Full diff:"
                color: textColor
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: fullDiffColorId
                width: 100
                height: rowHeight - 10
                placeholderText: qsTr("color")
                text: elementDiffFullColor
                onPressed: {
                    context = "fulldiff"
                    colorDialog.open()
                }
                onEditingFinished: {
                    elementDiffFullColor = fullDiffColorId.text
                }
            }
        }
        Row {
            spacing: 4
            Text {
                text: "Partial diff:"
                color: textColor
                width: labelWidth
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: partDiffColorId
                width: 100
                height: rowHeight - 10
                placeholderText: qsTr("color")
                text: elementDiffPartColor
                onPressed: {
                    context = "partdiff"
                    colorDialog.open()
                }
                onEditingFinished: {
                    elementDiffPartColor = partDiffColorId.text
                }
            }
        }
        ColorDialog {
            id: colorDialog
            onSelectedColorChanged: {
                if (context === "border")
                    borderColor = selectedColor
                else if (context === "text")
                    textColor = selectedColor
                else if (context === "fulldiff")
                    elementDiffFullColor = selectedColor
                else if (context === "partdiff")
                    elementDiffPartColor = selectedColor
            }
        }
    }
    
    Component.onCompleted: {
        //colorDialog.open()
    }
}