import QtQuick
import QtQuick.Controls

Item {
    id: cldRoot

    property var innerMargin: 0

    signal rowClicked(var row)

    Row {
        width: parent.width
        anchors.top: parent.top
        anchors.margins: innerMargin
        anchors.bottom: parent.bottom
        Text {
            id: lineNumberId
            text: "<span>" + lineNumber + 
                        '&nbsp;'.repeat(
                            (cldRoot.ListView.view.model.rowCount().toString().length + 1) - 
                                lineNumber.toString().length) + "</span>"
            color: "#888888"
            font.pointSize: pointSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter 
        }
        Rectangle {
            clip: true
            height: parent.height
            width: parent.width - lineNumberId.width
            anchors.verticalCenter: parent.verticalCenter
            color: (lineBgColor.length && lineReal) ? lineBgColor : Material.background
            Canvas {
                id: patternCanvas
                visible: !lineReal
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext('2d');
                    ctx.fillStyle = ctx.createPattern("#888888", Qt.BDiagPattern); 
                    ctx.fillRect(0, 0, width, height);
                    ctx.stroke();
                }
            }
            Text {
                color: textColor
                anchors.fill: parent
                font.pointSize: pointSize
                verticalAlignment: Text.AlignVCenter
                text: "<span>" + lineIndentSymbol.repeat(lineIndent)  + 
                    lineText.replace(/ /g, '&nbsp;') + "</span>"
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: rowClicked(lineNumber)
    }
}