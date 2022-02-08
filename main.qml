import QtQuick 2.11
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 1.0
import io.singleton 1.0

Window {
    id: root
    visible: true
    title: qsTr("edit")
    width: screen.width
    height: screen.height

    property int rotation: 0
    property string doc: "# reMarkable key-writer"
    property int mode: 0
    property int lastCursorPostion: -1
    property bool ctrlPressed: false
    property bool isOmni: false
    property string omniQuery: ""
    property string currentFile: "scratch.md"
    property string folder: "file://%1/edit/".arg(home_dir)

    function toggleMode() {
        if (mode == 0) {
            mode = 1
            query.cursorPosition = lastCursorPostion == -1 ? query.length : lastCursorPostion
        } else {
            doc = query.text
            lastCursorPostion = query.cursorPosition
            mode = 0
        }
        saveFile()
    }

    function doLoad(name) {
        var xhr = new XMLHttpRequest
        xhr.open("GET", folder + name)
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var response = xhr.responseText
                isOmni = false
                mode = 0
                currentFile = name
                doc = response

            }
        }
        xhr.send()
    }

    function saveFile() {
        console.log("Save " + currentFile)
        var fileUrl = folder + currentFile
        console.log(fileUrl)
        var request = new XMLHttpRequest()
        request.open("PUT", fileUrl, false)
        request.send(doc)
        console.log("save -> " + request.status + " " + request.statusText)
        return request.status
    }

    function initFile(name) {
        console.log("Init " + name)
        var fileUrl = folder + name + ".md"
        var request = new XMLHttpRequest()
        request.open("PUT", fileUrl, false)
        request.send("# " + name)
        console.log("save -> " + request.status + " " + request.statusText)
        return request.status
    }

    function handleKeyDown(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = true
        } else if (event.key === Qt.Key_K && ctrlPressed) {
            isOmni = !isOmni
            event.accepted = true
        } else if (event.key === Qt.Key_Q && ctrlPressed) {
            Qt.quit()
        }
    }
    function handleKeyUp(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = false
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (isOmni) {
                isOmni = false
            } else {

                toggleMode()
            }
        }

        if (mode == 0)
            switch (event.key) {
            case Qt.Key_Home:
                Qt.quit()
                break
            case Qt.Key_Right:
                if (ctrlPressed)
                    root.rotation = (root.rotation + 90) % 360
                break
            case Qt.Key_Left:
                if (ctrlPressed)
                    root.rotation = (root.rotation - 90) % 360
                break
            }
    }

    Component.onCompleted: {
        doLoad(currentFile)
    }

    Rectangle {
        rotation: root.rotation
        id: body
        width: root.rotation % 180 ? root.height : root.width
        height: root.rotation % 180 ? root.width : root.height
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
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: query.paintedWidth
            bottomMargin: parent.height /2

            contentHeight: query.paintedHeight
            clip: true

            function ensureVisible(r) {
                if (contentX >= r.x) {
                    contentX = r.x
                } else if (contentX + width <= r.x + r.width) {
                    contentX = r.x + r.width - width
                }
                if (contentY >= r.y) {
                    if (r.y-height/2 > 0)
                        contentY = r.y-height/2
                    else
                        contentY = 0
                } else if (contentY + height <= r.y + r.height) {
                    contentY = r.y + r.height - height/2
                }
            }

            function scrollUp() {
                contentY -= 400
                if (contentY < 0) contentY = 0
            }
            function scrollDown() {
                contentY += 400
            }

            TextEdit {
                id: query
                width: body.width
                height: body.height
                Keys.enabled: true
                wrapMode: TextEdit.Wrap
                textMargin: 12
                textFormat: mode == 0 ? TextEdit.RichText : TextEdit.PlainText
                font.family: mode == 0 ? "Noto Sans" : "Noto Mono"
                text: mode == 0 ? utils.markdown(doc) : doc
                focus: !isOmni
                renderType: Text.NativeRendering
                Component {
                    id: curDelegate
                    Item {
                        width: 18
                        visible: query.cursorVisible
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            color: "black"
                            height: 2
                            width: parent.width
                        }
                    }
                }
                cursorDelegate: curDelegate
                readOnly: mode == 0 ? true : false
                font.pointSize: mode == 0 ? 12 : 10

                onLinkActivated: {
                    console.log("Link activated: " + link)
                    doLoad(link)
                }

                Keys.onPressed: {
                    switch(event.key){
                        case Qt.Key_Down:
                        case Qt.Key_Left:
                            if (mode == 0)
                                flick.scrollDown()
                            break
                        case Qt.Key_Up:
                        case Qt.Key_Right:
                            if (mode == 0)
                                flick.scrollUp()
                            break
                        case Qt.Key_PageUp:
                            query.cursorPosition -= 100
                            break
                        case Qt.Key_PageDown:
                            query.cursorPosition += 100
                            break
                        default:
                            handleKeyDown(event)
                            break
                    }
                }

                Keys.onReleased: {
                    handleKeyUp(event)
                    handleKey(event)
                }

                onCursorRectangleChanged: {
                    flick.ensureVisible(cursorRectangle)
                }
            }
        }

        Rectangle {
            id: quick
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: parent.height * 0.6
            color: "black"
            visible: isOmni ? true : false
            radius: 20
            border.width: 5
            border.color: "gray"

            TextEdit {
                id: omniQueryTextEdit
                text: omniQuery
                textFormat: TextEdit.PlainText
                x: 40
                width: parent.width - 20
                color: "white"
                font.pointSize: 24
                font.family: "Noto Mono"
                focus: isOmni
                Keys.enabled: true
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Return) {
                        saveFile()
                        if (!omniList.currentItem) {
                            initFile(omniQuery)
                            doLoad(omniQuery + ".md")
                        } else {
                            doLoad(omniList.currentItem.text)
                        }
                        isOmni = false
                        event.accepted = true
                        return
                    }

                    handleKeyDown(event)
                }
                Keys.onReleased: {
                    handleKeyUp(event)
                    handleKey(event)
                    omniQuery = omniQueryTextEdit.text
                    folderModel.nameFilters = [omniQuery + "*"]
                }

                Keys.forwardTo: omniList
            }
            ListView {
                id: omniList
                anchors.top: omniQueryTextEdit.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.rightMargin: 40
                anchors.right: parent.right
                highlightResizeDuration: 0
                highlight: Rectangle {
                    color: "white"
                    radius: 5
                    width: 600
                }
                Component {
                    id: fileDelegate
                    Text {
                        width: parent.width
                        text: fileName
                        color: ListView.isCurrentItem ? "black" : "white"
                    }
                }

                model: folderModel
                delegate: fileDelegate
            }
        }
    }
}
