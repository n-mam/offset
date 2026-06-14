import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Loader {

    id: loader
    property var used
    property var free
    property var value
    property string text
    property var checked
    property string color

    required property string type
    required property bool create

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
            id: bar
            border.width: 1
            border.color: borderColor
            color: "mintcream"
            Item {
                clip: true
                anchors.fill: parent
                anchors.margins: bar.border.width
                Rectangle {
                    id: used
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width:  {
                        if (loader.used <= 0) return 0
                        var w = parent.width * loader.used / (loader.used + loader.free)
                        return Math.max(2, w)   // always show at least 2 px
                    }
                    color: "#ADDEFC"
                }
            }

            Text {
                id: usedText
                text: loader.used > 1
                    ? loader.used.toFixed(1) + "g"
                    : (loader.used * 1024).toFixed(1) + "m"
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                z: 1
            }
            Text {
                id: freeText
                text: loader.free > 1
                    ? loader.free.toFixed(1) + "g"
                    : (loader.free * 1024).toFixed(1) + "m"
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                z: 1
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
                radius: 4
                implicitWidth: size
                implicitHeight: size
                readonly property int size: 12
                border.color: cb.down ? "black" : "darkgrey"
                Rectangle {
                    radius: 3
                    height: width
                    visible: cb.checked
                    width: parent.size/2
                    anchors.centerIn: parent
                    color: cb.down ? "darkgrey" : "black"
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
        } else {
            loader.width = loader.height = 0
        }
    }
}
