import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material 2.12

Loader {
  id: loader

  required property string type
  required property bool create

  property string text
  property string color

  property var used
  property var free
  property var value
  property var checked

  function percent(one, two) {
    return (one/(one + two)) * 100
  }

  Component {
    id: textComponent
    Text {
      text: loader.text
      color: loader.color
    }
  }

  Component {
    id: progressComponent
    ProgressBar {
      from: 0
      to: 100
      value: loader.value
    }
  }

  Component {
    id: usageComponent
    Rectangle {
      radius: 3
      border.width: 1
      border.color: borderColor
      color: Material.background
      Rectangle {
        id: used
        x: parent.x
        radius: 3
        width: loader.width * (loader.used / (loader.used + loader.free))
        height: parent.height
        color: "#ADDEFC" //lightskyblue"
        anchors.left: parent.left
        Text {
          text: loader.used > 1 ?
                  loader.used.toFixed(1) + "g" :
                  (loader.used * 1024).toFixed(1) + "m"
          anchors.horizontalCenter: percent(loader.used, loader.free) < 10 ? undefined : used.horizontalCenter
          anchors.left: percent(loader.used, loader.free) < 10 ? used.left : undefined
          anchors.verticalCenter: used.verticalCenter
        }
      }
      Rectangle {
        id: remaining
        radius: 3
        x: used.x + used.width
        width: loader.width - used.width
        height: parent.height
        color: "mintcream"
        anchors.right: parent.right
        Text {
          text: loader.free > 1 ?
                  loader.free.toFixed(1) + "g":
                  (loader.free * 1024).toFixed(1) + "m"
          anchors.horizontalCenter: percent(loader.free, loader.used) < 10 ? undefined : remaining.horizontalCenter
          anchors.right: percent(loader.free, loader.used) < 10 ? remaining.right : undefined
          anchors.verticalCenter: remaining.verticalCenter
        }
      }
    }
  }

  Component {
    id: checkBoxComponent
    CheckBox {
      id: cb
      checked: loader.checked
      implicitWidth: indicator.width
      indicator: Rectangle {
        readonly property int size: 12
        implicitWidth: size
        implicitHeight: size
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
        rowDelegate.selectionChanged(checkState === Qt.Checked)
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
      else if (type === "progress") {
        loader.sourceComponent = progressComponent
      }
      else {
        loader.sourceComponent = undefined
      }
    }
    else {
      loader.width = loader.height = 0
    }
  }
}
