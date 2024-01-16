import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {

    property var context
    property var rowHeight: 45
    property var labelWidth: 100

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
            color: diffColor
            Text {
                color: textColor
                text: "Test"
                anchors.centerIn: parent
            }
        }
    }

    Flickable {
        clip: true
        anchors.fill: parent
        anchors.margins: 10
        contentHeight: parent.height
        contentWidth: parent.width

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
                    text: "Diff:"
                    color: textColor
                    width: labelWidth
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: diffColorId
                    width: 100
                    height: rowHeight - 10
                    placeholderText: qsTr("color")
                    text: diffColor
                    onPressed: {
                        context = "diff"
                        colorDialog.open()
                    }
                    onEditingFinished: {
                        diffColor = diffColorId.text
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
                    else if (context === "diff")
                        diffColor = selectedColor                        
                }
            }
        }
    }
        Component.onCompleted: {
            //colorDialog.open()
        }
}