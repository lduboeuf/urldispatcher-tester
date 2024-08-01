/*
 * Copyright (C) 2024  Your FullName
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * urldispatchertest.ldub is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3 as Popups
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'urldispatchertest.ldub'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property var history: []
    property var prefixModel: []
    property string selectedPrefix: ""
    property bool applicationActive: Qt.application.state === Qt.ApplicationActive

    Settings {
        id: settings
        property alias history: root.history
    }

    onHistoryChanged: populate()


    function populateDefaultHistory() {
        var h = ["http://docs.ubports.com", "https://ubports.com",
                 "https://youtube.be/@UBports",
                 "calendar:///startdate=2024-08-18T00:00:00Z",
                 "tel:0123456789",
                 "sms:0123456779",
                 "sms:911",
                 "alarm://",
                 "weather://"]
        root.history = h
    }

    function append(url) {
        var h = root.history
        if (!h.includes(url)) {

            h.push(textbox.text)
            h.sort()
            root.history = h
        }
    }

    function remove(url) {

        var h = root.history
        const idx = h.indexOf(url)
        if (idx > -1) {
            h.splice(idx, 1);
        }
        h.splice(idx, 1);
        root.history = h
    }

    function populate() {

        let prefixes = []
        urlModel.clear()
        history.forEach( h => {
            const prefix =  h.substr(0, h.indexOf(':'))
            if (!prefixes.includes(prefix)) {
                prefixes.push(prefix)
            }

            urlModel.append({ url: h})

        })

        prefixes.sort()
        console.log('prefixes', prefixes)

        root.prefixModel = prefixes
    }

    function openUrl(url) {
        urlSentChecked.restart()
        console.log("Sending URL: " + url)
        let res = Qt.openUrlExternally(url)
        if (!res) {
            console.log("Sending URL: " + url + " failed")
        }
        //root.append(url)


    }

    ListModel {
        id: urlModel
    }

    SortFilterModel {
        id: filterUrlModel
        model: urlModel
        sort {
            property: "url"
            order: Qt.AscendingOrder
        }
        filter {
            property: "url"
            //Add i for case insensitive
            pattern: new RegExp(root.selectedPrefix, "i")
        }
    }

    Timer {
        id: urlSentChecked
        interval: 1000

        onTriggered: {
            console.log('oulala urlSentChecked', root.applicationActive)
            if (root.applicationActive) {
                PopupUtils.open(popoverComponent, sendUrlBtn)
            } else {
                root.append(textbox.text)
            }
        }
    }

    Page {
        id: page
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('URL Dispatcher tester')
            extension: ActionBar {

                id: actionBar
                numberOfSlots: 2

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: units.gu(1)
                }

                actions: [
                    Action {
                        iconName: "next"
                        text: root.selectedPrefix
                        visible: root.selectedPrefix.length > 0
                    },
                    Action {
                        iconName: "view-grid-symbolic"
                        text: i18n.tr("All prefixes")
                        onTriggered: {
                            root.selectedPrefix = ""
                            textbox.text = ""
                            prefixGrid.forceActiveFocus()
                        }
                    }
                ]

                delegate: AbstractButton {
                    id: button
                    action: modelData
                    width: label.width + icon.width + units.gu(3)
                    height: parent.height
                    Rectangle {
                        color: LomiriColors.slate
                        opacity: 0.1
                        anchors.fill: parent
                        visible: button.pressed
                    }
                    Icon {
                        id: icon
                        anchors.verticalCenter: parent.verticalCenter
                        name: action.iconName
                        width: units.gu(2)
                    }

                    Label {
                        anchors.centerIn: parent
                        anchors.leftMargin: units.gu(2)
                        id: label
                        text: action.text
                    }
                }
            }
        }

        ColumnLayout {
            id: controls
            spacing: units.gu(1)
            anchors {
                top: header.bottom
                margins: units.gu(2)
                left: parent.left
                right: parent.right
            }

            TextField {
                id: textbox
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                placeholderText: i18n.tr("URL (e.g. 'https://ubports.com')")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            }

            Button {
                id: sendUrlBtn
                Layout.fillWidth: true
                color: theme.palette.normal.positive
                text: i18n.tr("Send URL")
                enabled: /^([a-z]{2,}:[a-z0-9\/\/]+)/.test(textbox.text)
                onClicked: openUrl(textbox.text)
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: LomiriColors.silk
            }
        }

        GridLayout {
            id: prefixGrid
            visible: root.selectedPrefix.length === 0

            anchors {
                top: controls.bottom
                margins: units.gu(2)
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            columns: 3

            Repeater {
                model: root.prefixModel

                LomiriShape {
                    color: mouseArea.pressed ? theme.palette.selected.foreground : theme.palette.normal.foreground
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Label {
                        anchors.centerIn: parent
                        text: modelData
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            root.selectedPrefix = modelData + ":"
                            textbox.text = root.selectedPrefix
                            textbox.forceActiveFocus()
                        }
                    }

                }
            }

        }

        ListView {
            visible: root.selectedPrefix.length > 0
            anchors {
                top: controls.bottom
                topMargin: units.gu(2)
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            flickableDirection: ListView.StopAtBounds
            model: filterUrlModel
            clip: true
            delegate: ListItem {
                height: itemLayout.height + divider.height
                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            onTriggered: {
                                root.remove(url)
                            }
                        }
                    ]
                }

                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "send"
                            onTriggered: {
                                textbox.text = url
                                Qt.openUrlExternally(url)
                            }
                        }
                    ]
                }

                ListItemLayout {
                    id: itemLayout
                    title.text: url

                    ProgressionSlot { }
                }

                onClicked: {
                    // openUrl(modelData)
                    textbox.text = modelData
                    textbox.forceActiveFocus()
                    //Qt.openUrlExternally(modelData)

                }
            }

        }

        Component {
            id: popoverComponent

            Popups.Dialog {
                id: popover
                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    Label {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        fontSize: "medium"
                        wrapMode: Label.WordWrap
                        text: i18n.tr("If nothing happens, this url scheme might not be supported, check `lomiri-url-dispatcher-dump` in terminal for a complete list of registered url scheme")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: PopupUtils.close(popover)
                }

                Connections {
                    target: __eventGrabber
                    onPressed: PopupUtils.close(popover)
                }

            }
        }

    }

    Component.onCompleted: {
        if (root.history.length ===0) {
            root.populateDefaultHistory()
        } else {
            // fix calendar url
            let h = root.history
            const index = h.findIndex( element => element === "calendar://startdate=2024-08-18T00:00:00Z")
            if (index !== -1) {
                h[index] = "calendar:///startdate=2024-08-18T00:00:00Z";
                root.history = h
            }
        }
    }

}
