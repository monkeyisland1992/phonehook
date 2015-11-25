import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    anchors.fill: parent

    PageHeader {
        id: header
        title: qsTr("Available Sources")
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: serverBots.status == XmlListModel.Loading
    }

    Label {
        anchors.centerIn: parent
        text: qsTr("Failed to load")
        visible: serverBots.status == XmlListModel.Error || serverBots.status == XmlListModel.Null
    }

    XmlListModel {
        id: serverBots
        source: "http://phonehook.omnight.com/bots.ashx?country=" + _bots.country + (_bots.testSources ? "&beta=True" : "")
        query: "/bots/bot"

        XmlRole { name: "name"; query: "meta/name/string()" }
        XmlRole { name: "country"; query: "meta/country/string()" }
        XmlRole { name: "revision"; query: "meta/revision/string()" }
        XmlRole { name: "description"; query: "meta/description/string()" }
        XmlRole { name: "icon"; query: "meta/icon/string()" }
        XmlRole { name: "link"; query: "meta/link/string()" }
        XmlRole { name: "capabilities"; query: "string-join(meta/capabilities/capability/string(),'|')" }
        XmlRole { name: "file"; query: "file/string()" }
        XmlRole { name: "minversion"; query: "meta/minversion/string()" }
        XmlRole { name: "sort_key"; query: "meta/sort_key/string()" }

        property int retries: 0

        onStatusChanged: {
            console.log('load status changed - ', status);
            if(status == XmlListModel.Error) {
                if(retries < 3) {
                    retries++;
                    var bsource = source;
                    source = "";
                    source = bsource;
                }
            }

            if(status == XmlListModel.Ready) {
                expandMap = [ get(0).sort_key ]
                var e = {};
                for(var i=0; i < count; i ++) {
                    if(!e[get(i).sort_key]) e[get(i).sort_key] = 1;
                    else e[get(i).sort_key]++;
                }
                sectionCount = e;
            }

        }
    }

    property variant expandMap: [ ]
    property variant sectionCount: { 0 : 0 }

    function isExpanded(section) {
        return expandMap.indexOf(section) != -1;
    }

    function expand(section) {
        if(expandMap.indexOf(section) == -1) {
            var e = expandMap;
            e.push(section);
            expandMap = e;
        }
    }

    function contract(section) {
        var i = expandMap.indexOf(section);
        if(i != -1) {
            var e = expandMap;
            e.splice(i,1);
            expandMap = e;
        }
    }

    function toggle(section) {
        if(isExpanded(section)) contract(section)
        else                    expand(section)
    }

    ListView {
        id: botListView
        model: serverBots
        anchors.fill: parent
        anchors.topMargin: header.height
        clip: true
        section.property: "sort_key"


        footer: Item {
            width: parent.width
            height: 150
            Item {
                height: 20
                width: parent.width
            }

            Text {
                anchors.margins: Theme.paddingLarge
                anchors.left: parent.left
                anchors.right: parent.right
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                text: qsTr("All names and logos listed here are properties of respective rights holders. Phonehook is not endorsed by any of these services. ")
            }
        }

        section.delegate: Item {

            property string sectionCountry: /\|(.*)/.exec(section)[1]
            property bool expanded

            width: parent.width
            height: 70

            Row {
                id: countryNameLine
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: flag
                    anchors.verticalCenter: parent.verticalCenter
                    source: "http://phonehook.omnight.com/flags/" + sectionCountry + ".png"

                    Rectangle {
                        anchors.left: parent.right
                        anchors.top: parent.bottom
                        anchors.leftMargin: -10
                        anchors.topMargin: -20
                        radius: 5
                        color: "#222255"
                        height: cLabel.height
                        width: cLabel.width+10
                        opacity: .8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: cLabel
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Bold
                            text: sectionCount[section]
                            color: Theme.primaryColor
                        }
                    }

                }

                Item {
                    height: parent.height
                    width: 20
                }

                Text {
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeMedium
                    text: _bots.getCountryName(sectionCountry)
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Image {
                source: "../images/expand.png"
                height: 31
                width: 30
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                rotation: isExpanded(section) ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.top: countryNameLine.bottom
                anchors.left: parent.left
                anchors.topMargin: -5
                height: 5
                color: "#44FFFFFF"
                width: parent.width
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    toggle(section)
                }
            }

        }

        delegate:
            BackgroundItem {
                id: delegate
                //height: 80
                anchors.left: parent.left
                anchors.right: parent.right

                height: isExpanded(sort_key) ? 80 : 0
                visible: isExpanded(sort_key) ? true : false

                Item {
                    height: 70
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: icon
                        height: 60
                        width: 60
                        fillMode: Image.PreserveAspectFit

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        //visible: typeof model.icon !== 'undefined'
                        source: model.icon || ''
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: icon.right
                        anchors.leftMargin: 10
                        text: model.name
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }

                    Component.onCompleted: {
                        var bstatus = _bots.botStatusCompare(model.name, model.revision)
                        checkedUpdated.visible = (bstatus == 2)
                        checkedInstalled.visible = (bstatus >= 1)
                    }

                    Connections {
                        target: _bots.botList
                        onCount_changed: {
                            var bstatus = _bots.botStatusCompare(model.name, model.revision)
                            checkedUpdated.visible = (bstatus == 2)
                            checkedInstalled.visible = (bstatus >= 1)
                        }
                    }

                    Image {
                        id: checkedUpdated
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: checkedInstalled.left
                        source: "../images/new-48.png"
                        height: parent.height*0.8
                        width: height
                        visible: false
                    }

                    Image {
                        id: checkedInstalled
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        source: "../images/approval-48.png"
                        height: parent.height*0.8
                        width: height
                        visible: false
                    }

                }

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PageBotDownload.qml"), { botData: model } )
                }
            }
    }
}
