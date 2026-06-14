import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/delegates"
import "qrc:/components"
import CustomElements 1.0

Item {

    id: compareFileRoot

    property var clickedRow: -1
    property var mergeDirection: ""

    // radius: 3
    // border.width: 1
    // border.color: borderColor
    // color: Material.background
    implicitHeight: parent.height
    implicitWidth: (parent.width / 2) - 1

    FileFolderSelector {
        id: fileSelector
        anchors.margins: 10
        placeholder: "File"
        anchors.topMargin: 12
        isFolderSelector: false
        anchors.top: parent.top
        image: "qrc:/folder.png"
        anchors.left: parent.left
        height: textFieldHeight
        anchors.right: parent.right
        onFileSelected: (file) => {
            onCompareFileUpdated(file)
        }
    }

    ListView {
        id: textListView
        clip: true
        currentIndex: -1
        anchors.margins: 10
        anchors.leftMargin: 4
        ScrollBar.vertical: vbar
        model: CompareFileModel{}
        anchors.left: parent.left
        highlightMoveDuration: 100
        highlightMoveVelocity: 800
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: fileSelector.bottom
        height: parent.height - fileSelector.height
        highlight: Rectangle { color: "lightsteelblue"; }
        delegate: CompareLineDelegate{
            height: 22
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
            }
            onDropped: (drop) => {
                var file = localPath(drop.urls[0])
                onCompareFileUpdated(file)
                fileSelector.setPath(file)
            }
            onExited: {}
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

    function setCurrentIndex(idx) {
        textListView.currentIndex = idx
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
