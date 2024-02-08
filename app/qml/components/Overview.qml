import QtQuick
import QtQml.Models
import QtQuick.Controls

Rectangle {
    
	property var modelA
    property var modelB
	signal iterateChange(var down)

	color: "transparent"
	anchors.verticalCenter: parent.verticalCenter

	Row {
		id: topRow
		anchors.margins: 2
		anchors.topMargin: 12
		anchors.top: parent.top
		height: textFieldHeight - 2
		anchors.horizontalCenter: parent.horizontalCenter
		ButtonX {
			id: prevChange
			width: 18
			height: 18
			image: "qrc:/up-diff.png"
			anchors.verticalCenter: parent.verticalCenter
			onButtonXClicked: iterateChange(false)
		}
		ButtonX {
			id: nextChange
			width: 18
			height: 18
			image: "qrc:/down-diff.png"
			anchors.verticalCenter: parent.verticalCenter
			onButtonXClicked: iterateChange(true)
		}
	}

	function update() {
		drawAtPercentOffset(70)
	}
	function drawAtPercentOffset(offset) {
		
	}
}