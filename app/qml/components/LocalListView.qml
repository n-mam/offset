import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls

Item {

    id: root
    implicitWidth: parent.width / 2

    required property var model
    required property var textlabel
    property int lastSelectedIndex: -1

    TextField {
        id: currentDirectory
        font.pointSize: 10
        anchors.margins: 10
        anchors.topMargin: 12
        height: textFieldHeight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        placeholderText: root.textlabel
        verticalAlignment: TextInput.AlignVCenter
        onAccepted: root.model.currentDirectory = currentDirectory.text
    }

    ListView {
        id: listView
        clip: true
        focus: true
        currentIndex: -1
        cacheBuffer: 1024
        model: root.model
        anchors.topMargin: 7
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.left: parent.left
        delegate: listItemDelegate
        anchors.right: parent.right
        anchors.top: currentDirectory.bottom
        anchors.bottom: spacer.top
        boundsBehavior: Flickable.StopAtBounds
        Connections {
            target: root.model
            function onDirectoryList() {
                root.model.UnselectAll()
                currentDirectory.text = root.model.currentDirectory
                var [files, folders] = root.model.totalFilesAndFolders.split(":")
                status.text = files + " files " + folders + " folders "
            }
        }
        MouseArea {
            z: -1
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    contextMenu.selectedIndex = -1;
                    let localPos = root.mapFromItem(listView, mouse.x, mouse.y);
                    contextMenu.popup(localPos.x, localPos.y);
                }
            }
        }
    }

    Rectangle {
        id: spacer
        color: Material.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusRect.top
        height: 3
        Shape {
            anchors.fill: spacer
            anchors.centerIn: spacer
            ShapePath {
                strokeColor: borderColor
                strokeStyle: ShapePath.SolidLine
                startX: 1; startY: 1
                PathLine {x: spacer.width; y: 1}
            }
        }
    }

    Rectangle {
        id: statusRect
        height: 25
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 5
        anchors.rightMargin: 2
        color: Material.background
        // radius: 3
        // border.width: 1
        // border.color: borderColor
        Text {
            id: status
            color: textColor
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }
    }

    Component {
        id: listItemDelegate
        Rectangle {
            id: delegateRect
            height: 24
            implicitHeight: 24
            implicitWidth: contentRow.implicitWidth + 6
            color: fileIsSelected ? "lightsteelblue" : "transparent"
            // radius: 3
            // border.width: 1
            // border.color: "#123"
            Row {
                id: contentRow
                spacing: 5
                anchors.leftMargin: 3
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: listItemIcon
                    width: 20; height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    source: fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
                }
                Text {
                    id: feText
                    text: fileName
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    color: fileIsSelected ? "black" : textColor
                }
            }
            MouseArea {
                preventStealing: true
                anchors.top: parent.top
                anchors.left: parent.left
                propagateComposedEvents: true
                anchors.bottom: parent.bottom
                acceptedButtons: Qt.AllButtons
                width: delegateRect.implicitWidth
                onDoubleClicked: {
                    if (fileIsDir) {
                        if (fileName === "..")
                            root.model.currentDirectory = root.model.getParentDirectory()
                        else
                            root.model.currentDirectory = root.model.currentDirectory +
                                (root.model.currentDirectory.endsWith(root.model.pathSeperator) ?
                                    fileName : (root.model.pathSeperator + fileName))
                    }
                }
                onClicked: (mouse) => {
                    if (fileName === "..") return
                    if (mouse.button === Qt.RightButton) {
                        if (!fileIsSelected){
                            root.model.UnselectAll();
                            fileIsSelected = true;
                        }
                        contextMenu.selectedIndex = index;
                        let localPos = root.mapFromItem(delegateRect, mouse.x, mouse.y);
                        contextMenu.popup(localPos.x, localPos.y);
                    } else {
                        let shiftPressed = mouse.modifiers & Qt.ShiftModifier;
                        let ctrlPressed = mouse.modifiers & Qt.ControlModifier;
                        if (shiftPressed && lastSelectedIndex >= 0) {
                            let start = Math.min(index, lastSelectedIndex)
                            let end = Math.max(index, lastSelectedIndex)
                            root.model.SelectRange(start, end);
                        } else if (ctrlPressed) {
                            root.model.SelectIndex(index, !root.model.get(index, "fileIsSelected"))
                            lastSelectedIndex = index
                        } else {
                            root.model.UnselectAll();
                            fileIsSelected = true;
                            lastSelectedIndex = index;
                        }
                    }
                }
            }
            Component.onCompleted: {
                if (fileName === ".") {
                    height = 0
                    visible = false
                }
            }
        }
    }

    RenameNewPopup {
        id: newRenamePopup
        context: ""
        elementName: ""
        elementIsDir: ""
        parent: listView
        onDismissed: (userInput) => {
            newRenamePopup.close()
            if (userInput.length) {
                if (context.startsWith("New folder")) {
                    root.model.CreateDirectory(currentDirectory.text + "/" + userInput)
                } else if (context.startsWith("Rename")) {
                    root.model.Rename(
                    currentDirectory.text + "/" + elementName,
                    currentDirectory.text + "/" + userInput)
                } else if (context.startsWith("Delete")) {
                    root.model.RemoveSelectedItems()
                }
                root.model.currentDirectory = root.model.currentDirectory
            }
        }
    }

    Menu {
        id: contextMenu
        property int selectedIndex: -1
        MenuItem {
            text: "Upload"
            onTriggered: root.model.QueueTransfers(true);
        }
        MenuItem {
            text: "Queue"
            onTriggered: root.model.QueueTransfers(false);
        }
        MenuItem {
            text: "New folder"
            onTriggered: {
                newRenamePopup.context = "New folder"
                newRenamePopup.inputHint = "Folder name"
                newRenamePopup.inputValue = ""
                newRenamePopup.open()
            }
        }
        MenuItem {
            text: "Rename"
            onTriggered: {
                var fileName = root.model.get(contextMenu.selectedIndex, "fileName")
                newRenamePopup.context = "Rename \"" + fileName + "\""
                newRenamePopup.elementName = fileName
                newRenamePopup.inputHint = "New name"
                newRenamePopup.inputValue = ""
                newRenamePopup.open()
            }
        }
        MenuItem {
            text: "Refresh"
            onTriggered: {
                logger.updateStatus(1, "Ready")
                root.model.currentDirectory = root.model.currentDirectory
            }
        }
        MenuItem {
            text: "Delete"
            onTriggered: {
                var fileName = root.model.get(contextMenu.selectedIndex, "fileName")
                var fileIsDir = root.model.get(contextMenu.selectedIndex, "fileIsDir")
                newRenamePopup.context = "Delete \"" + fileName + "\""
                newRenamePopup.elementName = fileName
                newRenamePopup.elementIsDir = fileIsDir
                newRenamePopup.inputHint = fileIsDir ? "Folder" : "File"
                newRenamePopup.inputValue = fileName
                newRenamePopup.open()
            }
        }
    }

    Component.onCompleted: root.model.currentDirectory = ""
}