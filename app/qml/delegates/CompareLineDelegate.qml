import QtQuick
import QtQuick.Controls

Item {

    id: cldRoot
    property var innerMargin: 0
    signal rowClicked(var row)

    Row {
        spacing: 4
        width: parent.width
        anchors.top: parent.top
        anchors.margins: innerMargin
        anchors.bottom: parent.bottom
        Image {
            id: mergeButton
            width: 14
            height: 14
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
            source: (!elementReal || elementDiffPart ||
                    elementDiffFull || elementDiffAdded) ?
                        (mergeDirection === "A2B" ?
                            "qrc:/right-arrow.png" : "qrc:/left-arrow.png") : ""
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: mergeButton.scale = 1 + (containsMouse ? 0.4 : 0)
                onClicked: {

                }
            }
        }
        Text {
            id: elementNumberId
            text: "<span>" + elementNumber +
                        '&nbsp;'.repeat(
                            (cldRoot.ListView.view.model.rowCount().toString().length + 1) -
                                elementNumber.toString().length) + "</span>"
            color: "#888888"
            font.pointSize: pointSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: textRect
            clip: true
            height: parent.height
            color: Material.background
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - elementNumberId.width - mergeButton.width
            Canvas {
                id: patternCanvas
                anchors.fill: parent
                visible: !elementReal
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
                textFormat: Text.RichText
                font.pointSize: pointSize
                verticalAlignment: Text.AlignVCenter
                text: indentSymbol.repeat(elementIndent) + markupText()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rowClicked(elementNumber)
    }

    function markupText() {
        var result = "";
        if (/*elementDiffPart &&*/ elementChildCount) {
            textRect.color = elementDiffPartColor
            elementChildren.forEach((child, i) => {
                //console.log(i, child.full, child.real, child.text);
                if (child.full) {
                    result += "<span style=\"background-color:" + charDiffColor + ";\">" +
                                    (child.text.length ? _replaceSpaces(child.text) : '&nbsp;') +
                                "</span>";
                } else if (child.added) {
                    result += "<span style=\"background-color:" + charAddedColor + ";\">" +
                                    (child.text.length ? _replaceSpaces(child.text) : '&nbsp;') +
                                "</span>";
                } else if (!child.real) {
                    result += "<span style=\"background-color:" + charNotRealColor + ";\">&nbsp;</span>";
                } else {
                    result += child.text.length ? _replaceSpaces(child.text) : '&nbsp;';
                }
            })
        } else {
            //console.log(elementDiffAdded, elementDiffFull, elementText)
            if (elementDiffAdded) {
                textRect.color = elementDiffAddedColor;
            } else if (elementDiffFull) {
                textRect.color = elementDiffFullColor;
            } else {
                textRect.color = Material.background;
            }
            result = _replaceSpaces(elementText);
        }
        return result;
    }
    function _replaceSpaces(s) {
        return s.replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/ /g, '&nbsp;')
                .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
    }
}