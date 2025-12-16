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

    SplitView {
        anchors.top: parent.top
        anchors.bottom: fxcFooter.top
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal

        Item {
            SplitView.preferredWidth: parent.width * 0.42
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
            id: recoverView
            Column {
                spacing: 5
                anchors.fill: parent
                anchors.margins: appSpacing
                GroupBox {
                    id: mountGroup
                    title: "Mount"
                    width: parent.width
                    Column {
                        spacing: appSpacing * 2
                        FileFolderSelector {
                            id: imagePath
                            height: 32
                            isFolderSelector: false
                            image: "qrc:/folder.png"
                            placeholder: "Image file"
                            width: parent.width * 0.75
                            anchors.horizontalCenter: parent.horizontalCenter
                            onFileSelected: (file) => {

                            }
                        }
                        Row {
                            id: mountRow
                            spacing: appSpacing
                            GroupBox {
                                title: "Mode"
                                Row {
                                    spacing: 5
                                    RadioButton {
                                        text: "Read-Only"
                                        checked: true
                                        height: 32
                                        width: 118
                                    }
                                    RadioButton {
                                        text: "Read-Write"
                                        height: 32
                                        width: 125
                                    }
                                }
                            }
                            Row {
                                spacing: 5
                                anchors.bottom: parent.bottom
                                Label {
                                    text: "Drive:"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                ComboBox {
                                    width: 75
                                    model: ["Z:", "Y:", "X:"]
                                }
                                Label {
                                    text: "Partition:"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                TextField {
                                    width: 40
                                    text: "0"
                                    inputMethodHints: Qt.ImhDigitsOnly
                                }
                            }
                        }
                        Row {
                            spacing: appSpacing
                            GroupBox {
                                title: "Write"
                                Row {
                                    spacing: appSpacing
                                    RadioButton {
                                        text: "Type1"
                                        height: 32
                                    }
                                    RadioButton {
                                        text: "Type2"
                                        checked: true
                                        height: 32
                                    }
                                    RadioButton {
                                        text: "Direct"
                                        height: 32
                                    }
                                }
                            }
                            Row {
                                spacing: appSpacing
                                anchors.bottom: parent.bottom
                                Label {
                                    text: "Size:"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                TextField {
                                    width: 50
                                }
                                CheckBox {
                                    text: "Encrypt"
                                }
                            }
                        }
                        Button {
                            width: 90
                            text: "Mount"
                            anchors.horizontalCenter: parent.horizontalCenter
                            onClicked: function() {
                                recoverManager.imageFile = imagePath.text
                                recoverManager.mount()
                            }
                        }
                    }
                }
                // GroupBox {
                //     id: imageGroup
                //     title: "Image"
                //     width: parent.width
                // }
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