import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"
import CustomElements 1.0

Rectangle {

    radius: 3
    border.width: 1
    border.color: borderColor
    color: Material.background
    implicitWidth: parent.width / 2
    implicitHeight: parent.height

    FileFolderSelector {
        id: fileSelector
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: 43
        label: ".."
        placeholder: "File"
        isFolderSelector: false
        onFileSelected: (file) => {
            textListView.model.document = file
        }
    }

    ListView {
        id: textListView
        clip: true
        model: TextModel{}
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: fileSelector.bottom
        anchors.margins: 4
        width: parent.width
        height: parent.height - fileSelector.height
        delegate: TextArea {
            width: ListView.view.width
            textFormat: TextEdit.RichText //TextEdit.PlainText
            activeFocusOnPress: true
            wrapMode: Text.NoWrap
            selectByMouse: true
            selectByKeyboard: true
            font.weight: Font.Normal
            font.pointSize: 10
            text: "<div style='color:#339AF0;'>" + lineNumber + lineIndentSymbol.repeat(4 + lineIndent) + "</div>" + lineText
            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 12
                border.color: "transparent"
                color: Material.background
            }
        }
    }
}
