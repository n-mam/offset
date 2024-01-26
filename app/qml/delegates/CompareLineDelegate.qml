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
            width: parent.width - elementNumberId.width
            anchors.verticalCenter: parent.verticalCenter
            Canvas {
                id: patternCanvas
                visible: !elementReal
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
                                    (child.text.length ? _replaceFrontBackSpaces(child.text) : '&nbsp;') +
                                "</span>";
                } else if (child.added) {
                    result += "<span style=\"background-color:" + charAddedColor + ";\">" +
                                    (child.text.length ? _replaceFrontBackSpaces(child.text) : '&nbsp;') +
                                "</span>";
                } else if (!child.real) {
                    result += "<span style=\"background-color:" + charNotRealColor + ";\">&nbsp;</span>";
                } else {
                    result += child.text.length ? _replaceFrontBackSpaces(child.text) : '&nbsp;';
                }
            })
        } else {
            //console.log(elementDiffAdded, elementDiffFull)
            if (elementDiffAdded) {
                textRect.color = elementDiffAddedColor;
            } else if (elementDiffFull) {
                textRect.color = elementDiffFullColor;
            } else {
                textRect.color = Material.background;
            }
            result = elementText;
        }
        return _replaceFrontBackSpaces(result);
    }

    function _trimLeft(s) {
        for (let i = 0; i < s.length; i++) {
            if (s[i] !== ' ') {
                return s.substring(i);
            }
        }
        return "";
    }
    function _trimRight(s) {
        for (let i = (s.length - 1); i >= 0; i--) {
            if (s[i] !== ' ') {
                return s.substring(0, i + 1);
            }
        }
        return "";
    }
    function _replaceFrontBackSpaces(s) {
        var n_leading_spaces = s.length - _trimLeft(s).length;
        var n_trailing_spaces = s.length - _trimRight(s).length;
        let ss = s.trim();
        if (ss === "") return '&nbsp;';
        for (let i = 0; i < n_leading_spaces; i++)
            ss = '&nbsp;' + ss;
        for (let i = 0; i < n_trailing_spaces; i++)
            ss = ss + '&nbsp;';
        return ss
    }
}