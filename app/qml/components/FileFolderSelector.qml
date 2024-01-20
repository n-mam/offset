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

    Row {
        spacing: appSpacing
        anchors.fill: parent
        anchors.top: parent.top
        TextField {
            id: destination
            font.pointSize: 10
            height: parent.height
            placeholderText: placeholder
            verticalAlignment: TextInput.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - appSpacing - folderButton.width
            text: isFolderSelector ? folderDialog.folder : fileDialog.file
        }
        ButtonX {
            id: folderButton
            width: 28
            height: 28
            text: fileFolderSelector.label
            image: fileFolderSelector.image
            anchors.verticalCenter: parent.verticalCenter
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