import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Item {

    required property var label
    required property var placeholder
    required property var isFolderSelector

    signal fileSelected(var file)
    signal folderSelected(var folder)

    Rectangle {
        id: destRect
        width: parent.width
        height: 40
        anchors.top: parent.top
        anchors.topMargin: 8
        color: "transparent"
        // radius: 3
        // border.width: 1
        // border.color: borderColor
        TextField {
            id: destination
            width: (parent.width * 0.80) - (2 * appSpacing)
            height: parent.height * 0.85
            anchors.left: parent.left
            anchors.leftMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            text: isFolderSelector ? folderDialog.folder : fileDialog.file
            placeholderText: placeholder
            verticalAlignment: TextInput.AlignVCenter
        }
        Button {
            text: label
            width: (parent.width * 0.17) - appSpacing
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 7
           // anchors.bottom: parent.bottom
            onClicked: isFolderSelector ? folderDialog.open() : fileDialog.open()
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    FileDialog {
        id: fileDialog
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            var path = fileDialog.file.toString();
            path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            var file = decodeURIComponent(path).replace(/\//g, "\\")
            fileSelected(file)
            destination.text = file
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: {
            var path = folderDialog.folder.toString();
            path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            destination.text = decodeURIComponent(path).replace(/\//g, "\\")
        }
    }
}