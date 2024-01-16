import QtQuick
import QtQuick.Controls

Item {
    id: cldRoot
    signal rowClicked(var row)

    Row {
        anchors.fill: parent
        Text {
            id: lineNumberId
            text: "<span>" + lineNumber + 
                        lineIndentSymbol.repeat(
                            (cldRoot.ListView.view.model.rowCount().toString().length + 1) - 
                                lineNumber.toString().length) + "</span>"
            color: "#339AF0"
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
                    ctx.fillStyle = ctx.createPattern("#808080", Qt.BDiagPattern); 
                    ctx.fillRect(0, 0, width, height);
                    ctx.stroke();
                }
            }
            Text {
                anchors.fill: parent
                font.pointSize: pointSize
                verticalAlignment: Text.AlignVCenter
                color: lineTxColor.length ? lineTxColor : textColor
                text: "<span>" + lineText.replace(/ /g, '&nbsp;') + "</span>"
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: rowClicked(lineNumber)
    }
}