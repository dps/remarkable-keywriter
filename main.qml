import QtQuick 2.6
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 1.0
import io.singleton 1.0

Window {
    visible: true;
    title: qsTr("edit")
    width: 1404;
    height: 1872;

    property string doc: "# reMarkable key-writer";
    property int mode: 0;
    property bool ctrlPressed: false;
    property bool isOmni: false;
    property string omniQuery: "";
    property string currentFile: "scratch.md";

    EditUtils {
        id: utils
    }
    FolderListModel {
        folder: "file:///home/root/edit/"
        id: folderModel
        nameFilters: ["*.md"]
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    readonly property int dummy: onLoad();

    function toggleMode() {
        if (mode == 0) {
            mode = 1;
        } else {
            doc = query.text;
            mode = 0;
        }
        saveFile();
    }

    function doLoad(name) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "file:///home/root/edit/" + name);
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var response = xhr.responseText;
                isOmni = false;
                mode = 0;
                currentFile = name;
                doc = response;
            }
        };
        xhr.send();
    }

    function saveFile() {
        console.log("Save " + currentFile);
        var fileUrl = "file:///home/root/edit/" + currentFile;
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send(doc);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function initFile(name) {
        console.log("Init " + name);
        var fileUrl = "file:///home/root/edit/" + name + ".md";
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send("# " + name);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function handleKeyDown(event) {
        if (event.key == Qt.Key_Control) {
            ctrlPressed = true;
        } else if (event.key == Qt.Key_K && ctrlPressed) {
            isOmni = !isOmni;
            event.accepted = true;
        }
    }
    function handleKeyUp(event) {
        if (event.key == Qt.Key_Control) {
            ctrlPressed = false;
        }
    }

    function handleKey(event) {
        if (event.key == Qt.Key_Escape) {
            if (isOmni) {
                isOmni = false;
            } else {

                toggleMode();
            }
        }

        if (mode == 0 && event.key == Qt.Key_Home) {
            isOmni = !isOmni;
        }
    }

    function onLoad() {
        doLoad(currentFile);
        return 0;
    }

    Rectangle {
        rotation: 90
        anchors.top: parent.right
        y: 200
        width: 1404;
        height: 1404;
        color: "white"
        Flickable {
            id: flick
            width: 1404;
            height: 1404;
            contentWidth: query.paintedWidth
            contentHeight: query.paintedHeight
            clip: true

            function ensureVisible(r)
            {
                if (contentX >= r.x)
                    contentX = r.x;
                else if (contentX+width <= r.x+r.width)
                    contentX = r.x+r.width-width;
                if (contentY >= r.y)
                    contentY = r.y;
                else if (contentY+height <= r.y+r.height)
                    contentY = r.y+r.height-height;
            }

            function scrollUp() {
                contentY -= 400;
            }
            function scrollDown() {
                contentY += 400;
            }

            TextEdit {
                id: query;
                Keys.enabled: true;
                wrapMode: TextEdit.Wrap;
                textMargin: 12;
                width:1404;
                textFormat: mode == 0 ? TextEdit.RichText : TextEdit.PlainText;
                font.family: mode == 0 ? "Noto Sans" : "Noto Mono";
                text: mode == 0 ? utils.markdown(doc) : doc;
                focus: !isOmni;
                Component {
                    id: curDelegate
                    Rectangle { width:8; height: 20; visible: query.cursorVisible; color: "black";}
                }
                cursorDelegate: curDelegate;
                readOnly: mode == 0 ? true : false;
                font.pointSize: mode == 0 ? 12 : 18;

                onLinkActivated: {
                    console.log("Link activated: " + link);
                    doLoad(link);
                }

                Keys.onPressed: {
                    if (mode == 0 && (event.key == Qt.Key_Down || event.key == Qt.Key_Left)) {
                        flick.scrollDown();
                    }
                    if (mode == 0 && (event.key == Qt.Key_Up || event.key == Qt.Key_Right)) {
                        flick.scrollUp();
                    }

                    handleKeyDown(event);
                }

                Keys.onReleased: {
                    handleKeyUp(event);
                    handleKey(event);
                }

                onCursorRectangleChanged: {
                    flick.ensureVisible(cursorRectangle);
                }
            }
        }

    }
    Rectangle {
        id: quick
        rotation: 90
        anchors.centerIn: parent;
        width: 700;
        height: 400;
        color: "black"
        visible: isOmni ? true : false;
        radius: 20;
        border.width: 5;
        border.color: "gray";

        TextEdit {
            id: omniQueryTextEdit;
            text: omniQuery;
            textFormat: TextEdit.PlainText;
            x: 40;
            width:680;
            color: "white";
            font.pointSize: 24;
            font.family: "Noto Mono";
            focus: isOmni;
            Keys.enabled: true;
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    saveFile();
                    if (!omniList.currentItem) {
                        initFile(omniQuery);
                        doLoad(omniQuery + ".md");
                    } else {
                        doLoad(omniList.currentItem.text);
                    }
                    isOmni = false;
                    event.accepted = true;
                    return;
                }

                handleKeyDown(event);
            }
            Keys.onReleased: {
                handleKeyUp(event);
                handleKey(event);
                omniQuery = omniQueryTextEdit.text;
                folderModel.nameFilters = [omniQuery + "*"];
            }

            anchors {top: parent.top + 10; left: parent.left + 10}
            Keys.forwardTo: [omniList]
        }
        ListView {
            id: omniList;
            x: 40;
            width: 600; height: 300;
            anchors.top: omniQueryTextEdit.bottom;
            highlight: Rectangle { color: "white"; radius: 5;width: 600; }
            Component {
                id: fileDelegate
                Text { width:600; text: fileName; color: ListView.isCurrentItem ? "black" : "white";}
            }

            model: folderModel
            delegate: fileDelegate
        }

    }

}
