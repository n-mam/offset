import QtQuick
import QtQuick.Controls

Popup {
  contentItem: Item {
    anchors.fill: parent
    anchors.topMargin: 3
    anchors.leftMargin: 7
    anchors.rightMargin: 7
    Rectangle {
      id: popupLabel
      color: "transparent"
      width: parent.width
      height: parent.height * 0.05
      Text {
        color: textColor
        text: "Exclude list"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
    Rectangle {
      id: popupText
      radius: 3
      border.width: 1
      anchors.margins: 2
      width: parent.width
      color: "transparent"
      border.color: borderColor
      height: parent.height * 0.80
      anchors.top: popupLabel.bottom
      ScrollView {
        anchors.fill: parent
        TextArea {
          id: excludeListTextArea
          background: null
          textMargin: 4
        }
      }
    }
    Rectangle {
      // radius: 3
      // border.width: 1
      // border.color: borderColor
      color: "transparent"
      height: parent.height * 0.15
      anchors.top: popupText.bottom
      width: 75 + 75 + (3 * appSpacing)
      anchors.horizontalCenter: parent.horizontalCenter
      Button {
        width: 90
        text: "OK"
        anchors.left: parent.left
        height: parent.height * 0.90
        anchors.verticalCenter: parent.verticalCenter
        onClicked: function() {
          model.excludeList = []
          model.excludeList = excludeListTextArea.text.split("\n").filter(item =>
          item && item.toString().replace(/\s+/,'') || item === 0);
          popup.close()
        }
      }
      Button {
        width: 90
        text: "Cancel"
        onClicked: popup.close()
        anchors.right: parent.right
        anchors.margins: appSpacing
        height: parent.height * 0.90
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
  onOpened: {
    excludeListTextArea.clear()
    model.excludeList.forEach((file) => {
        excludeListTextArea.append(file)
    })
  }
}