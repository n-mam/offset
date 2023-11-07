import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {

    property var context
    property var rowHeight: 45
    property var labelWidth: 100

    Rectangle {
        id: testRect
        width: 300
        height: 200
        anchors.top: parent.top
        anchors.right: parent.right
        radius: 2
        border.width: 1
        border.color: borderColor
        color: "transparent"
        Text {
            color: textColor
            text: "this is a test rectangle"
            anchors.centerIn: parent
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
            ColorDialog {
                id: colorDialog
                onSelectedColorChanged: {
                    if (context === "border")
                        borderColor = selectedColor
                    else if (context === "text")
                        textColor = selectedColor
                }
            }
        }
    }
        Component.onCompleted: {
            //colorDialog.open()
        }
}