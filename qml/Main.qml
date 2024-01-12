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
//import QtQuick.Controls 2.2
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

    Settings {
        id: settings
        property alias history: root.history
    }

    onHistoryChanged: populatePrefixes()

    function populateDefaultHistory() {
        var h = ["https://ubports.com",
                 "https://youtube.be/@UBports",
                 "calendar://startdate=2024-08-18T00:00:00Z",
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
          return h.match(regex)[0]
        })

        const d = [...new Set([...defaultPrefixes ,...data])];
        console.log('prefixes', d)


        prefixModel.model = d
    }

    Page {
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

            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignRight
                Layout.preferredHeight: prefixSelector.expanded ? prefixSelector.expandedHeight : prefixSelector.collapsedHeight
                ComboButton {

                    id: prefixSelector
                    Layout.preferredWidth: units.gu(12)
                    Layout.alignment: Qt.AlignTop
                    expandedHeight: collapsedHeight + units.gu(6) * Math.min(prefixModel.count, 4)
                    comboList:  ListView {
                        id: prefixModel

                        delegate: ListItem {
                            height: prefixLayout.height + (divider.visible ? divider.height : 0)
                            onClicked: {
                                prefixSelector.text = modelData
                                textbox.text = modelData
                                textbox.cursorPosition = textbox.text.length
                                prefixSelector.expanded = false
                            }

                            ListItemLayout {
                                id: prefixLayout
                                title.text: modelData

                            }
                        }
                    }
                }
                TextField {
                    id: textbox
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    placeholderText: i18n.tr("URL (e.g. 'https://ubports.com')")
                }
            }

            Button {
                Layout.fillWidth: true

                text: i18n.tr("Send URL")
                enabled: /^([a-z]{2,}:[a-z\/\/]+)/.test(textbox.text)
                onClicked: {
                    console.log("Sending URL: " + textbox.text)
                    let res = Qt.openUrlExternally(textbox.text)
                    if (!res) {
                        console.log("Sending URL: " + textbox.text + " failed")
                    }
                    root.append(textbox.text)
                }
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
                ListItemLayout {
                    id: itemLayout
                    title.text: modelData
                }
                onClicked: {
                    textbox.text = modelData
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.history.length ===0) {
            root.populateDefaultHistory()
        }
    }
}