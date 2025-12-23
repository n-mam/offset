import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import "qrc:/components"

Rectangle {
    radius: 3
    border.width: 1
    border.color: borderColor
    color: Material.background
    width: parent.width
    height: parent.height
    clip: true

    SplitView {
        anchors.top: parent.top
        anchors.bottom: fxcFooter.top
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal

        Item {
            clip: true
            SplitView.preferredWidth: parent.width * 0.60
            List {
                id: devlist
                width: parent.width
                height: parent.height * 0.85
                model: diskListModel
                Connections {
                    target: diskListModel
                    function onTransferChanged(transfer) {}
                }
            }
            Rectangle {
                id: actionsRect
                width: parent.width
                anchors.top: devlist.bottom
                height: parent.height * 0.15
                color: Material.background
                Column {
                    clip: true
                    anchors.fill: parent
                    spacing: appSpacing * 2
                    FileFolderSelector {
                        id: destinationSelector
                        height: 32
                        width: 380
                        isFolderSelector: true
                        image: "qrc:/folder.png"
                        placeholder: "Destination"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Row {
                        width: 240
                        height: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        ButtonX {
                            id: startButton
                            width: 120
                            text: "Start"
                            height: parent.height
                            enabled: (diskListModel.transfer === 0)
                            onButtonXClicked: {
                                diskListModel.convertSelectedItemsToVirtualDisks(destinationSelector.getPath())
                            }
                        }
                        ButtonX {
                            id: cancelbutton
                            width: 120
                            text: "Cancel"
                            height: parent.height
                            enabled: (diskListModel.transfer !== 0)
                            onButtonXClicked: {
                                diskListModel.stop = true;
                            }
                        }
                    }
                }
            }
        }
        Item {
            GroupBox {
                id: mountGroup
                title: "Mount"
                clip: true
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 5
                ColumnLayout {
                    spacing: appSpacing
                    GroupBox {
                        title: "Mode"
                        RowLayout {
                            RadioButton {
                                text: "Read-Only"
                                checked: true
                                Layout.maximumHeight: 35
                            }
                            RadioButton {
                                text: "Read-Write"
                                Layout.maximumHeight: 35
                            }
                        }
                    }
                    GroupBox {
                        title: "Write"
                        RowLayout {
                            spacing: appSpacing
                            RadioButton {
                                text: "Type1"
                                Layout.maximumHeight: 35
                            }
                            RadioButton {
                                text: "Type2"
                                checked: true
                                Layout.maximumHeight: 35
                            }
                            RadioButton {
                                text: "Direct"
                                Layout.maximumHeight: 35
                            }
                        }
                    }
                    RowLayout {
                        spacing: appSpacing
                        Label {
                            text: "Drive:"
                        }
                        ComboBox {
                            model: ["Z:", "Y:", "X:"]
                            Layout.maximumWidth: 70
                            Layout.maximumHeight: 35
                        }
                        Label {
                            text: "Partition:"
                        }
                        TextField {
                            text: "0"
                            Layout.maximumWidth: 50
                            Layout.maximumHeight: 35
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }
                    RowLayout {
                        spacing: appSpacing
                        Label {
                            text: "Size:"
                        }
                        TextField {
                            Layout.maximumWidth: 50
                            Layout.maximumHeight: 35
                        }
                        CheckBox {
                            text: "Encrypt"
                        }
                    }
                    Button {
                        text: "Mount"
                        Layout.alignment: Qt.AlignCenter
                        onClicked: function() {
                            recoverManager.imageFile = imagePath.text
                            recoverManager.mount()
                        }
                    }
                }
            }
            GroupBox {
                id: imageGroup
                title: "Image"
                clip: true
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mountGroup.bottom
                anchors.margins: 5
                ColumnLayout {
                    spacing: appSpacing
                    RowLayout {
                        spacing: 3
                        Label {
                            text: "Source:"
                        }
                        TextField {
                            id: source
                            Layout.maximumHeight: 32
                            placeholderText: "image"
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.minimumWidth: imageGroup.width * 0.65
                        }
                    }
                    RowLayout {
                        Label {
                            text: "Target:"
                        }
                        TextField {
                            id: target
                            Layout.maximumHeight: 32
                            placeholderText: "block device"
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.minimumWidth: imageGroup.width * 0.65
                        }
                    }
                    Button {
                        text: "Recover"
                        Layout.maximumWidth: 110
                        Layout.maximumHeight: 58
                        Layout.alignment: Qt.AlignCenter
                        onClicked: function() {
                            diskListModel.recoverVirtualDisk(source.text, target.text);
                        }
                    }
                }
            }
        }
    }

    FxcFooter {
        id: fxcFooter
        height: 25
        //width: parent.width
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        Connections {
            target: logger
            function onUpdateStatus(key, status) {
                if (key === 0) {
                    fxcFooter.currentStatus = status
                }
            }
        }
    }
}