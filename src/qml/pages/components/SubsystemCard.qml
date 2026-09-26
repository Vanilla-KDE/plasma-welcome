/*
 * SPDX-FileCopyrightText: 2026 Fangcat_Dev <fangcat_dev@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: subsystemCardRoot

    property string subsystemTitle: i18nc("@title", "Set up the system")
    // Injected from the page, which reads it from the external apps.json
    // ("subsystem" -> "commands"). Accepts a list of commands, or a single
    // string with one command per line.
    property var subsystemCommand: []

    property string subsystemStatus: "pending"   // pending | installing | installed | failed
    property string subsystemLog: ""

    // Blank lines and surrounding whitespace are ignored.
    readonly property var subsystemCommands: {
        const raw = subsystemCardRoot.subsystemCommand;
        const list = Array.isArray(raw) ? raw : String(raw).split("\n");
        return list.map(function(line) {
            return String(line).trim();
        }).filter(function(line) {
            return line.length > 0;
        });
    }

    // Injected from the parent page.
    property color cardBorderColor: Qt.rgba(0, 0, 0, 0.25)

    signal logRequested(string title, string log)

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.largeSpacing
    Layout.bottomMargin: Kirigami.Units.largeSpacing

    color: Kirigami.Theme.backgroundColor
    radius: Kirigami.Units.smallSpacing

    border.width: 1
    border.color: subsystemCardRoot.cardBorderColor

    implicitHeight: subsystemLayout.implicitHeight
                    + (Kirigami.Units.largeSpacing * 2)

    ColumnLayout {
        id: subsystemLayout
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            margins: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: subsystemCardRoot.subsystemTitle
                font.weight: Font.DemiBold
            }

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                visible: subsystemCardRoot.subsystemStatus !== "pending"

                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    visible: subsystemCardRoot.subsystemStatus === "installing"
                    running: visible
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: "dialog-ok-apply"
                    color: Kirigami.Theme.positiveTextColor
                    visible: subsystemCardRoot.subsystemStatus === "installed"
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: "dialog-error"
                    color: Kirigami.Theme.negativeTextColor
                    visible: subsystemCardRoot.subsystemStatus === "failed"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: subsystemCardRoot.logRequested(subsystemCardRoot.subsystemTitle,
                                                                 subsystemCardRoot.subsystemLog)
                    }
                }
            }
        }
    }
}
