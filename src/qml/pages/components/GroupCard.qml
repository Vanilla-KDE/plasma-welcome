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
    id: groupCardRoot

    required property var modelData
    required property int index

    // Injected from the parent page.
    property var iconCache: ({})
    property bool installing: false
    property color cardBorderColor: Qt.rgba(0, 0, 0, 0.25)

    signal groupToggled(int groupIndex, bool checked)
    signal groupExpandToggled(int groupIndex)
    signal appToggled(int groupIndex, int appIndex, bool checked)
    signal logRequested(string title, string log)

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.largeSpacing
    Layout.bottomMargin: Kirigami.Units.largeSpacing

    color: Kirigami.Theme.backgroundColor
    radius: Kirigami.Units.smallSpacing

    border.width: 1
    border.color: groupCardRoot.cardBorderColor

    implicitHeight: groupLayout.implicitHeight + (Kirigami.Units.largeSpacing * 2)

    ColumnLayout {
        id: groupLayout
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
                text: groupCardRoot.modelData.name
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.weight: Font.DemiBold
            }

            QQC2.Switch {
                checked: groupCardRoot.modelData.allSelected
                enabled: !groupCardRoot.installing
                onToggled: groupCardRoot.groupToggled(groupCardRoot.index, checked)
            }

            QQC2.ToolButton {
                text: groupCardRoot.modelData.expanded ? "▾" : "▸"
                onClicked: groupCardRoot.groupExpandToggled(groupCardRoot.index)
            }
        }

        QQC2.Label {
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: i18nc("@info", "%1 selected of %2",
                         groupCardRoot.modelData.selectedCount,
                         groupCardRoot.modelData.apps.length)
            color: Kirigami.Theme.disabledTextColor
            visible: groupCardRoot.modelData.expanded
        }

        ColumnLayout {
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: 0
            Layout.fillWidth: true
            visible: groupCardRoot.modelData.expanded
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: groupCardRoot.modelData.apps

                delegate: AppCard {
                    groupIndex: groupCardRoot.index
                    iconCache: groupCardRoot.iconCache
                    installing: groupCardRoot.installing
                    cardBorderColor: groupCardRoot.cardBorderColor
                    onAppToggled: function(groupIndex, appIndex, checked) {
                        groupCardRoot.appToggled(groupIndex, appIndex, checked)
                    }
                    onLogRequested: function(title, log) {
                        groupCardRoot.logRequested(title, log)
                    }
                }
            }
        }
    }
}
