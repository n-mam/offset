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
        text: "Exclude list"
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
    Rectangle {
      id: popupText
      radius: 3
      border.width: 1
      border.color: "#FFFFFF"
      color: "transparent"
      width: parent.width
      height: parent.height * 0.80
      anchors.top: popupLabel.bottom
      anchors.margins: 2
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
      // border.color: "#FFFFFF"
      color: "transparent"
      width: 75 + 75 + (3 * appSpacing)
      height: parent.height * 0.15
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: popupText.bottom
      Button {
        text: "OK"
        width: 90
        height: parent.height * 0.90
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        onClicked: function() {
          model.excludeList = []
          model.excludeList = excludeListTextArea.text.split("\n").filter(item =>
          item && item.toString().replace(/\s+/,'') || item === 0);
          popup.close()
        }
      }
      Button {
        text: "Cancel"
        width: 90
        height: parent.height * 0.90
        anchors.right: parent.right
        anchors.margins: appSpacing
        anchors.verticalCenter: parent.verticalCenter
        onClicked: popup.close()
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