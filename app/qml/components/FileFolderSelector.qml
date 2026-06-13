import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls

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
            text: isFolderSelector ? folderDialog.currentFolder : fileDialog.selectedFile
        }
        ButtonX {
            id: folderButton
            width: parent.height * 0.70
            height: parent.height * 0.70
            text: fileFolderSelector.label
            image: fileFolderSelector.image
            anchors.verticalCenter: parent.verticalCenter
            onButtonXClicked: isFolderSelector ? folderDialog.open() : fileDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        title: "Load File"
        fileMode: FileDialog.OpenFile
        nameFilters: [ "All Files (*)" ]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)
        onAccepted: {
            fileSelected(fileDialog.selectedFile)
            destination.text = localPath(fileDialog.selectedFile)
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: {
            destination.text = localPath(folderDialog.currentFolder)
        }
    }

    function localPath(url) {
        let path;
        if (url.toLocalFile)
            path = url.toLocalFile();
        else {
            path = url.toString();
            if (Qt.platform.os === "windows")
                path = path.replace(/^file:\/\/\//, "");
            else
                path = path.replace(/^file:\/\//, "");
        }
        return decodeURIComponent(path);
    }   
}