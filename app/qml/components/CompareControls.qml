import QtQuick
import QtQml.Models
import QtQuick.Controls

Item {
    signal iterateChange(var down)
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
                var lcs_len = compareManager.compare()
                var endTime = new Date();
                var tt = Math.round(endTime - startTime);
                lcsLength.text = "lcs: " + lcs_len + ", "
                timeTaken.text = "time: " + ((tt > 1000) ? ((tt / 1000) + "s") : (tt + "ms"))
            }
        }
    }
    Row {
        id: rightRow
        spacing: 4
        anchors.margins: 10
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        ButtonX {
            id: prevChange
            width: 20
            height: 20
            image: "qrc:/up-diff.png"
            anchors.verticalCenter: parent.verticalCenter
            onButtonXClicked: iterateChange(false)
        }
        ButtonX {
            id: nextChange
            width: 20
            height: 20
            image: "qrc:/down-diff.png"
            anchors.verticalCenter: parent.verticalCenter
            onButtonXClicked: iterateChange(true)
        }
        Text {
            text: "  "
        }
        Text {
            id: lcsLength
            text: ""
            color: textColor
        }
        Text {
            id: timeTaken
            text: ""
            color: textColor
        }
    }
}