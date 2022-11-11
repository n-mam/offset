import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 2.12

ListView {
  id: listView
  clip: true
  currentIndex: -1
  Rectangle {
    width: 18
    height: 18
    color: "transparent"
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 4
    radius: 3
    border.width: 1
    border.color: "grey"
    Text {
      text: "R"
      color: "white"
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter
    }
    MouseArea {
      hoverEnabled: true
      anchors.fill: parent
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: { 
        model.RefreshModel()
      }
    }
  }
  delegate: Rectangle {
    id: listDelegate
    // radius: 5
    // border.width: 1
    // border.color: "grey"
    width: listView.width
    implicitHeight: rd.height
    color: Material.background
    visible: model.visible
    enabled: model.visible

    property var originalHeight;

    RowDelegate {
      id: rd
      depth: model.depthRole
      hasChildren: model.hasChildrenRole
      onToggleTreeNode: (index, expanded) => {
        listView.model.ToggleTreeAtIndex(index, expanded)
      }
    }
    TapHandler {
      //onTapped: console.log("list row tapped")
    }
    Connections {
      target: diskListModel
      function onDataChanged() {
        listDelegate.height = model.visible ? listDelegate.originalHeight : 0
      }
    }
    Component.onCompleted: {
      originalHeight = listDelegate.height
    }
  }
}