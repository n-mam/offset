import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/delegates"
import "qrc:/components"
import CustomElements 1.0

Rectangle {

    id: compareFileRoot

    property var clickedRow: -1

    radius: 3
    border.width: 1
    border.color: borderColor
    color: Material.background
    implicitHeight: parent.height
    implicitWidth: (parent.width / 2) - 1

    FileFolderSelector {
        id: fileSelector
        height: 34
        label: ".."
        anchors.margins: 4
        placeholder: "File"
        isFolderSelector: false
        anchors.top: parent.top
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
            onRowClicked: (row) => {
                clickedRow = row
            }
        }
        DropArea {
            id: compareFileDropArea;
            anchors.fill: parent
            onEntered: (drag) => {
                drag.accept (Qt.LinkAction);
                compareFileRoot.border.color = "gray";
            }
            onDropped: (drop) => {
                console.log(drop.urls)
                var path = drop.urls[0].toString();
                path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
                var file = decodeURIComponent(path).replace(/\//g, "\\")
                onCompareFileUpdated(file)
            }
            onExited: {
                compareFileRoot.border.color = borderColor;
            }
        }
    }

    function onCompareFileUpdated(file) {
        textListView.model.document = file
    }

    function getCompareFile() {
        return textListView.model.document
    }

    function getModel() {
        return textListView.model
    }
}
