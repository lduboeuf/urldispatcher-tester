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
    property bool applicationActive: Qt.application.state === Qt.ApplicationActive

    Settings {
        id: settings
        property alias history: root.history
    }

    onHistoryChanged: populatePrefixes()


    function populateDefaultHistory() {
        var h = ["https://ubports.com",
                 "https://youtube.be/@UBports",
                 "calendar:///startdate=2024-08-18T00:00:00Z",
                 "tel://0123456789",
                 "sms://0123456779",
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

    function remove(index) {
        var h = root.history
        h.splice(index, 1);
        root.history = h
    }

    function populatePrefixes() {
        const regex = /^([a-z]{2,}:(\/+)?)/g;
        const defaultPrefixes = ['http://', 'https://']
        const data = history.map(h => {
                                     const m = h.match(regex)
                                     if (m) {
                                         return m[0]
                                     }
                                 })

        const d = [...new Set([...defaultPrefixes ,...data])];
        d.sort()
        console.log('prefixes', d)


        root.prefixModel = d
    }

    function openUrl(url) {
        urlSentChecked.restart()
        console.log("Sending URL: " + url)
        let res = Qt.openUrlExternally(url)
        if (!res) {
            console.log("Sending URL: " + url + " failed")
        }
        root.append(url)


    }

    Timer {
        id: urlSentChecked
        interval: 1000

        onTriggered: {
            console.log('oulala urlSentChecked', root.applicationActive)
            if (root.applicationActive) {
                PopupUtils.open(popoverComponent, sendUrlBtn)
            }
        }
    }

    Page {
        id: page
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('URL Dispatcher tester')
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

            Button {
                Layout.alignment: Qt.AlignLeft
                text: i18n.tr("prefix")
                onTriggered: {
                    var dialog = PopupUtils.open(choosePrefixDialog, page, {
                                                     'model': root.prefixModel
                                                 });
                    dialog.selectedPrefix.connect(
                                function(prefix) {
                                    textbox.text = prefix
                                    textbox.cursorPosition = textbox.text.length
                                    textbox.forceActiveFocus()
                                })
                }

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
                enabled: /^([a-z]{2,}:[a-z\/\/]+)/.test(textbox.text)
                onClicked: openUrl(textbox.text)
            }
        }

        ListView {

            anchors {
                top: controls.bottom
                topMargin: units.gu(2)
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            flickableDirection: ListView.StopAtBounds
            model: history
            clip: true
            delegate: ListItem {
                height: itemLayout.height + divider.height
                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            onTriggered: {
                                root.remove(index)
                            }
                        }
                    ]
                }

                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "send"
                            onTriggered: {
                                textbox.text = modelData
                                Qt.openUrlExternally(modelData)
                            }
                        }
                    ]
                }

                ListItemLayout {
                    id: itemLayout
                    title.text: modelData

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
            id: choosePrefixDialog
            Popups.Dialog {
                id: dialog
                property var model
                title: i18n.tr("Select a prefix")
                modal:true

                signal selectedPrefix(string prefix)

                ListView {
                    id: prefixModel
                    model: dialog.model
                    height: childrenRect.height
                    flickableDirection: ListView.StopAtBounds
                    delegate: ListItem {
                        height: prefixLayout.height + (divider.visible ? divider.height : 0)
                        onClicked: {
                            dialog.selectedPrefix(modelData)
                            PopupUtils.close(dialog)
                        }

                        ListItemLayout {
                            id: prefixLayout
                            title.text: modelData

                        }

                    }
                }

                Connections {
                    target: __eventGrabber
                    onPressed: PopupUtils.close(dialog)
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
