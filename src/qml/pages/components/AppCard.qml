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
    id: appCardRoot

    required property var modelData
    required property int index

    // Injected from the parent.
    property int groupIndex: -1
    property var iconCache: ({})
    property bool installing: false
    property color cardBorderColor: Qt.rgba(0, 0, 0, 0.25)

    signal appToggled(int groupIndex, int appIndex, bool checked)
    signal logRequested(string title, string log)

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.smallSpacing
    Layout.bottomMargin: Kirigami.Units.smallSpacing

    color: Kirigami.Theme.alternateBackgroundColor
    radius: Kirigami.Units.smallSpacing

    border.width: 1
    border.color: appCardRoot.cardBorderColor

    implicitHeight: appRow.implicitHeight + (Kirigami.Units.smallSpacing * 2)

    RowLayout {
        id: appRow
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        Image {
            source: appCardRoot.iconCache[appCardRoot.modelData.id] || ""
            sourceSize.width: 32
            sourceSize.height: 32
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectFit
            visible: source != ""

            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: appCardRoot.modelData.name
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            visible: appCardRoot.modelData.selected

            QQC2.BusyIndicator {
                anchors.centerIn: parent
                width: 24
                height: 24
                visible: appCardRoot.modelData.installStatus === "installing"
                running: visible
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: "dialog-ok-apply"
                color: Kirigami.Theme.positiveTextColor
                visible: appCardRoot.modelData.installStatus === "installed"
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: "dialog-error"
                color: Kirigami.Theme.negativeTextColor
                visible: appCardRoot.modelData.installStatus === "failed"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appCardRoot.logRequested(appCardRoot.modelData.name,
                                                       appCardRoot.modelData.installLog)
                }
            }
        }

        QQC2.Switch {
            checked: appCardRoot.modelData.selected
            enabled: !appCardRoot.installing
            onToggled: appCardRoot.appToggled(appCardRoot.groupIndex,
                                              appCardRoot.index,
                                              checked)
        }
    }
}
