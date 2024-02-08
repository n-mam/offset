import QtQuick
import QtQml.Models
import QtQuick.Controls

Item {
    signal comparisonDone
    Row {
        id: leftRow
        spacing: 4
        anchors.margins: 10
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        ButtonX {
            text: "-"
            width: 24
            height: 26
            onButtonXClicked: pointSize -= 1
        }
        TextField {
            width: 46
            height: 26
            color: textColor
            font.pointSize: 8
            text: pointSize.toString()
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            onAccepted: pointSize = parseInt(text, 10)
        }
        ButtonX {
            text: "+"
            width: 24
            height: 26
            onButtonXClicked: pointSize += 1
        }
    }
    Row {
        id: middleRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        ButtonX {
            width: 62
            height: 26
            text: "Compare"
            onButtonXClicked: () => {
                var startTime = new Date();
                compareManager.compare()
                comparisonDone()
                var endTime = new Date();
                var tt = Math.round(endTime - startTime);
                timeTaken.text = "time: " + ((tt > 1000) ? ((tt / 1000) + "s") : (tt + "ms"))
            }
        }
    }
    Row {
        id: rightRow
        spacing: 2
        anchors.margins: appSpacing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: " "
        }
        Text {
            id: timeTaken
            text: ""
            color: textColor
        }
    }
}