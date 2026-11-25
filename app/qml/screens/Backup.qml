import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Controls.Material
import "qrc:/components"

Rectangle {
    id: root
    radius: 3
    border.width: 1
    border.color: borderColor
    color: Material.background
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600
    clip: true

    SplitView {
        id: mainSplitView
        anchors.top: parent.top
        anchors.bottom: fxcFooter.top
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal

        Item {
            id: conversionPanel
            clip: true
            SplitView.preferredWidth: mainSplitView.width * 0.50
            SplitView.minimumWidth: 350
            SplitView.fillWidth: true
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                List {
                    id: devlist
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: diskListModel
                    Connections {
                        target: diskListModel
                        function onTransferChanged(transfer) {
                            // Transfer state is reflected by the UI.
                        }
                    }
                }
                Rectangle {
                    id: actionsRect
                    Layout.fillWidth: true
                    Layout.preferredHeight: 115
                    color: Material.background
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: appSpacing
                        FileFolderSelector {
                            id: destinationSelector
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 380
                            Layout.maximumWidth: parent.width
                            Layout.preferredHeight: 32
                            isFolderSelector: true
                            image: "qrc:/folder.png"
                            placeholder: "Destination"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0
                            ButtonX {
                                id: startButton
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 32
                                text: "Start"
                                enabled: diskListModel.transfer === 0
                                         && destinationSelector.getText().trim().length > 0
                                onButtonXClicked: {
                                    diskListModel.convertSelectedItemsToVirtualDisks(
                                        destinationSelector.getText().trim()
                                    )
                                }
                            }
                            ButtonX {
                                id: cancelButton
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 32
                                text: "Cancel"
                                enabled: diskListModel.transfer !== 0
                                onButtonXClicked: {
                                    diskListModel.stop = true
                                }
                            }
                        }
                    }
                }
            }
        }
        Item {
            id: rightPanel
            SplitView.preferredWidth: mainSplitView.width * 0.50
            SplitView.minimumWidth: 300
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 8
                GroupBox {
                    id: mountGroup
                    title: "Mount"
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    clip: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: appSpacing
                        // Mount mode
                        GroupBox {
                            title: "Mode"
                            Layout.fillWidth: true
                            ButtonGroup {
                                id: modeGroup
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: appSpacing
                                RadioButton {
                                    id: readOnlyMode
                                    text: "Read-Only"
                                    checked: true
                                    ButtonGroup.group: modeGroup
                                    Layout.maximumHeight: 35
                                }
                                RadioButton {
                                    id: readWriteMode
                                    text: "Read-Write"
                                    ButtonGroup.group: modeGroup
                                    Layout.maximumHeight: 35
                                }
                            }
                        }
                        GroupBox {
                            title: "Write"
                            Layout.fillWidth: true
                            ButtonGroup {
                                id: writeGroup
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: appSpacing
                                RadioButton {
                                    id: type1Mode
                                    text: "Type1"
                                    ButtonGroup.group: writeGroup
                                    Layout.maximumHeight: 35
                                }
                                RadioButton {
                                    id: type2Mode
                                    text: "Type2"
                                    checked: true
                                    ButtonGroup.group: writeGroup
                                    Layout.maximumHeight: 35
                                }
                                RadioButton {
                                    id: directMode
                                    text: "Direct"
                                    ButtonGroup.group: writeGroup
                                    Layout.maximumHeight: 35
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: appSpacing
                            Label {
                                text: "Drive:"
                            }
                            ComboBox {
                                id: driveSelector
                                model: ["Z:", "Y:", "X:"]
                                Layout.preferredWidth: 75
                                Layout.maximumHeight: 35
                            }
                            Label {
                                text: "Partition:"
                            }
                            TextField {
                                id: partitionField
                                text: "0"
                                Layout.preferredWidth: 55
                                Layout.maximumHeight: 35
                                validator: IntValidator {
                                    bottom: 0
                                }
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: appSpacing
                            Label {
                                text: "Size:"
                            }
                            TextField {
                                id: sizeField
                                Layout.preferredWidth: 65
                                Layout.maximumHeight: 35
                                placeholderText: "Size"
                                validator: IntValidator {
                                    bottom: 0
                                }
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                            CheckBox {
                                id: encryptCheck
                                text: "Encrypt"
                            }
                        }
                        Button {
                            id: mountButton
                            text: "Mount"
                            Layout.alignment: Qt.AlignHCenter
                            enabled: partitionField.acceptableInput
                                     && sizeField.acceptableInput
                            onClicked: {
                                if (partitionField.text.trim().length === 0)
                                    return
                                if (sizeField.text.trim().length === 0)
                                    return
                                recoverManager.imageFile = source.text.trim()
                                recoverManager.mount()
                            }
                        }
                    }
                }
                GroupBox {
                    id: imageGroup
                    title: "Image"
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    clip: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: appSpacing
                        // Source image
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Label {
                                text: "Source:"
                            }
                            TextField {
                                id: source
                                Layout.fillWidth: true
                                Layout.maximumHeight: 32
                                placeholderText: "Image file path"
                                selectByMouse: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Label {
                                text: "Target:"
                            }
                            TextField {
                                id: target
                                Layout.fillWidth: true
                                Layout.maximumHeight: 32
                                placeholderText: "Block device"
                                selectByMouse: true
                            }
                        }
                        Button {
                            id: recoverButton
                            text: "Recover"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 36
                            enabled: source.text.trim().length > 0
                                     && target.text.trim().length > 0
                                     && diskListModel.transfer === 0
                            onClicked: {
                                if (source.text.trim().length === 0
                                        || target.text.trim().length === 0) {
                                    return
                                }
                                diskListModel.recoverVirtualDisk(
                                    source.text.trim(),
                                    target.text.trim()
                                )
                            }
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    FxcFooter {
        id: fxcFooter
        height: 25
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