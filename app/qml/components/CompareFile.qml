import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/delegates"
import "qrc:/components"
import CustomElements 1.0

Rectangle {

    id: diffViewRoot
    required property var pointSize

    radius: 3
    border.width: 1
    border.color: borderColor
    color: Material.background
    implicitHeight: parent.height
    implicitWidth: (parent.width / 2) - 1

    FileFolderSelector {
        id: fileSelector
        height: 45
        label: ".."
        anchors.margins: 4
        placeholder: "File"
        isFolderSelector: false
        anchors.left: parent.left
        anchors.right: parent.right
        onFileSelected: (file) => {
            onCompareFileUpdated(file)
        }
    }

    ListView {
        id: textListView
        clip: true
        anchors.margins: 10
        ScrollBar.vertical: vbar
        model: CompareFileModel{}
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: fileSelector.bottom
        height: parent.height - fileSelector.height
        delegate: CompareLineDelegate{
            height: 26
            width: ListView.view.width
        }
        DropArea {
            id: diffViewDropArea;
            anchors.fill: parent
            onEntered: (drag) => {
                diffViewRoot.border.color = "gray";
                drag.accept (Qt.LinkAction);
            }
            onDropped: (drop) => {
                console.log(drop.urls)
                var path = drop.urls[0].toString();
                path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
                var file = decodeURIComponent(path).replace(/\//g, "\\")
                onCompareFileUpdated(file)
            }
            onExited: {
                diffViewRoot.border.color = borderColor;
            }
        }
    }

    function onCompareFileUpdated(file) {
        textListView.model.document = file
    }

    function getCompareFile() {
        return textListView.model.document
    }
}
