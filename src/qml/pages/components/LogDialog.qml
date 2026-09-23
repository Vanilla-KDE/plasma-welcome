/*
 * SPDX-FileCopyrightText: 2026 Fangcat_Dev <fangcat_dev@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Kirigami.Dialog {
    id: logDialogRoot

    property string appName: ""
    property string logText: ""

    title: i18nc("@title:window", "Install log: %1", logDialogRoot.appName)
    preferredWidth: Kirigami.Units.gridUnit * 30
    preferredHeight: Kirigami.Units.gridUnit * 20
    padding: Kirigami.Units.largeSpacing

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            QQC2.TextArea {
                text: logDialogRoot.logText
                readOnly: true
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                selectByMouse: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            QQC2.Button {
                text: i18nc("@action:button", "Close")
                onClicked: logDialogRoot.close()
            }
        }
    }
}
