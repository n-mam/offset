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
            id: textRect
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
                textFormat: Text.RichText
                font.pointSize: pointSize
                verticalAlignment: Text.AlignVCenter
                text: lineIndentSymbol.repeat(lineIndent) + markupTextLine()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rowClicked(lineNumber)
    }

    function markupTextLine() {

        var result = "";

        if (lineChildCount) {
            textRect.color = "#5a2626"
            lineChildren.forEach((child, i) => {
                //console.log(i, child.text, child.color, child.color.length, child.real);
                if (child.color.length > 0) {
                    result += "<span style=\"background-color:#be6060\">" + child.text.length ? child.text : '&nbsp;' + "</span>";
                } else if (child.real === false) {
                    result += "<span style=\"background-color:#be6060\">" + '&nbsp;' + "</span>";
                } else {
                    result += child.text.length ? child.text : '&nbsp;';
                }
            })
        } else {
            result = lineText;
        }

        return _replaceFrontBackSpaces(result, '&nbsp;');
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
    function _replaceFrontBackSpaces(s, ch) {
        var n_leading_spaces = s.length - _trimLeft(s).length;
        var n_trailing_spaces = s.length - _trimRight(s).length;
        var ss = ch.repeat(n_leading_spaces) + s.trim() + ch.repeat(n_trailing_spaces);
        //console.log(n_leading_spaces, n_trailing_spaces, new_text);
        return ss;
    }
}