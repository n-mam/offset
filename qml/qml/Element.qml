import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material 2.12

Loader {
  id: loader
  property string text
  property string color
  required property string type
  required property bool create
  
  Component {
    id: textComponent
    Text {
      text: loader.text
      color: loader.color
    }
  }

  Component {
    id: usageComponent
    Rectangle {
      radius: 2
      border.width: 1
      border.color: "#a7c497"
      color: Material.background
      Rectangle {
        id: used
        x: parent.x
        radius: 2
        width: loader.width * ((model.sizeRole - model.freeRole) / model.sizeRole)
        height: parent.height
        color: "lightskyblue"
        anchors.left: parent.left
        Text {
          text: (model.sizeRole - model.freeRole) > 1 ? 
                  (model.sizeRole - model.freeRole).toFixed(1) + "G" :
                  ((model.sizeRole - model.freeRole) * 1024).toFixed(1) + "M"
          anchors.horizontalCenter: used.horizontalCenter
          anchors.verticalCenter: used.verticalCenter
        }
      }
      Rectangle {
        id: remaining
        radius: 2
        x: used.x + used.width
        width: loader.width - used.width
        height: usage.height
        color: "mintcream"
        anchors.right: parent.right
        Text {
          text: model.freeRole > 1 ? 
                  model.freeRole.toFixed(1) + "G":
                  (model.freeRole * 1024).toFixed(1) + "M"
          anchors.horizontalCenter: remaining.horizontalCenter
          anchors.verticalCenter: remaining.verticalCenter
        }
      }
    }
  }

  Component {
    id: checkBoxComponent
    CheckBox {
      id: cb
      implicitWidth: indicator.width
      indicator: Rectangle {
        readonly property int size: 12
        implicitWidth: size
        implicitHeight: size
        y: parent.height / 2 - height / 2
        radius: 4
        border.color: cb.down ? "black" : "darkgrey"

        Rectangle {
          anchors.centerIn: parent
          width: parent.size/2
          height: width
          radius: 3
          color: cb.down ? "darkgrey" : "black"
          visible: cb.checked
        }
      }

      onClicked: {
        rowDelegate.updateItemSelection(model.display, (checkState !== Qt.Unchecked))
      }
    }
  }

  Component.onCompleted: {
    if (create) {
      if (type === "usage") {
        loader.sourceComponent = usageComponent
      }
      else if (type === "checkBox") {
        loader.sourceComponent = checkBoxComponent
      }
      else if (type === "text") {
        loader.sourceComponent = textComponent
      }
      else {
        loader.sourceComponent = undefined
      }
    }
  }
}
