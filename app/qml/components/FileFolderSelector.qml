import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Item {
    id: fileFolderSelector
    property var label: ""
    property var image: ""
    required property var placeholder
    required property var isFolderSelector

    signal fileSelected(var file)
    signal folderSelected(var folder)

    Rectangle {
        id: destRect
        anchors.fill: parent
        anchors.topMargin: 8
        color: "transparent"
        anchors.top: parent.top
        // radius: 3
        // border.width: 1
        // border.color: borderColor
        TextField {
            id: destination
            font.pointSize: 10
            anchors.left: parent.left
            height: textFieldHeight - 4
            placeholderText: placeholder
            anchors.leftMargin: appSpacing
            verticalAlignment: TextInput.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            width: (parent.width - (3 * appSpacing)) * 0.93
            text: isFolderSelector ? folderDialog.folder : fileDialog.file
        }
        ButtonX {
            height: textFieldHeight - 4
            anchors.right: parent.right
            text: fileFolderSelector.label
            image: fileFolderSelector.image
            anchors.rightMargin: appSpacing
            anchors.verticalCenter: parent.verticalCenter
            width: (parent.width - (3 * appSpacing)) * 0.07
            onButtonXClicked: isFolderSelector ? folderDialog.open() : fileDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        folder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)
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