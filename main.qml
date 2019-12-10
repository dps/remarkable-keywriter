import QtQuick 2.6
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 1.0
import io.singleton 1.0

Window {
    id:root
    visible: true;
    title: qsTr("edit")
    width: screen.width;
    height: screen.height;

    property int rotation: 90
    property string doc: "# reMarkable key-writer";
    property int mode: 0;
    property bool ctrlPressed: false;
    property bool isOmni: false;
    property string omniQuery: "";
    property string currentFile: "scratch.md";
    property string folder: "file://" + home_dir + "/edit/"


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
            if (xhr.readyState === XMLHttpRequest.DONE) {
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
        var fileUrl = folder + currentFile;
        console.log(fileUrl);
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send(doc);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function initFile(name) {
        console.log("Init " + name);
        var fileUrl = folder + name + ".md";
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send("# " + name);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function handleKeyDown(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = true;
        } else if (event.key === Qt.Key_K && ctrlPressed) {
            isOmni = !isOmni;
            event.accepted = true;
        } else if (event.key === Qt.Key_Q && ctrlPressed){
            Qt.quit();
        }
    }
    function handleKeyUp(event) {
        if (event.key == Qt.Key_Control) {
            ctrlPressed = false;
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (isOmni) {
                isOmni = false;
            } else {

                toggleMode();
            }
        }

        if (mode == 0)
            switch(event.key) {
                case Qt.Key_Home:
                    Qt.quit()
                    break;
                case Qt.Key_Right:
                    if (ctrlPressed)
                        root.rotation = (root.rotation+90) % 360
                    break;
                case Qt.Key_Left:
                    if (ctrlPressed)
                        root.rotation = (root.rotation-90) % 360
                    break;
            }
    }

    function onLoad() {
        doLoad(currentFile);
        return 0;
    }
    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    Rectangle {
        rotation: root.rotation
        id: body
        width: (root.rotation / 90 ) % 2 ? root.height : root.width
        height: (root.rotation / 90 ) % 2 ? root.width : root.height
        anchors.centerIn: parent
        color: "white"
        border.color: "black"
        border.width: 2
        EditUtils {
            id: utils
        }
        FolderListModel {
            id: folderModel
            folder: root.folder
            nameFilters: ["*.md"]
        }

        Flickable {
            id: flick
            anchors.fill: parent
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
                width: body.width
                height: body.height
                Keys.enabled: true;
                wrapMode: TextEdit.Wrap;
                textMargin: 12;
                textFormat: mode == 0 ? TextEdit.RichText : TextEdit.PlainText;
                font.family: mode == 0 ? "Noto Sans" : "Noto Mono";
                text: mode == 0 ? utils.markdown(doc) : doc;
                focus: !isOmni;
                renderType: Text.NativeRendering
                Component {
                    id: curDelegate
                    Item {
                        width:18;
                        visible: query.cursorVisible;
                        Rectangle {
                            anchors.bottom: parent.bottom
                            color: "black"
                            height:2
                            width:parent.width
                        }
                    }
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
        rotation: root.rotation
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
