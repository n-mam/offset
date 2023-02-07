import QtQuick
import QtQuick.Controls

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: Material.background
  clip: true

  ListModel {
    id: traceModel
    ListElement {line: ""}
  }

  CheckBox {
    id: traceEnable
    z: 2
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 3
    anchors.rightMargin: 15
    checked: true
    text: qsTr("Enable")
  }

  ListView {
    id: traceList
    clip: true
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 10
    anchors.topMargin: 5
    height: parent.height * 0.90
    ScrollBar.vertical: ScrollBar {
      width: 8
    }
    flickableDirection: Flickable.VerticalFlick    
    model: traceModel
    delegate: Item {
      width: ListView.view.width;
      height: 17
      Label { 
        text: line
        Component.onCompleted: font.pointSize = font.pointSize - 2
      }
    }
    Connections {
      target: logger
      enabled: (traceEnable.checkState === Qt.Checked)
      function onAddLogLine(severity, log) {
        for (var l of log.split("\n"))
          traceModel.append({
            line: new Date().toLocaleTimeString(Qt.locale(), 
            "hh:" + "mm:" + "ss:" + "zzz") + " " + l
          })
      }
    }
  }

  Rectangle {
    id: logActions
    // radius: 5
    // border.width: 1
    // border.color: borderColor
    anchors.top: traceList.bottom
    anchors.margins: 5
    color: Material.background
    anchors.horizontalCenter: parent.horizontalCenter
    width: 75 + 75 + (3 * appSpacing)
    height: parent.height * 0.08
    Button {
      id: clearButton
      width: 75
      text: "CLEAR"
      enabled: (diskListModel.transfer === 0)
      height: parent.height * 0.90
      anchors.left: parent.left
      anchors.margins: appSpacing
      anchors.verticalCenter: parent.verticalCenter
      onClicked: traceModel.clear()
    }
    Button {
      id: savebutton
      width: 75
      text: "SAVE"
      enabled: (diskListModel.transfer !== 0)
      height: parent.height * 0.90
      anchors.left: clearButton.right
      anchors.margins: appSpacing
      anchors.verticalCenter: parent.verticalCenter
      onClicked: {}
    }
  }
  onVisibleChanged: {
    if (visible)
      traceList.positionViewAtEnd()
  }
}