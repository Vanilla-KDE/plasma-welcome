/*
 *  SPDX-FileCopyrightText: 2026 Fangcat_Dev <f20091219@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasma.welcome as Welcome

Welcome.Page {
    id: root

    heading: i18nc("@title", "System Updates")
    description: i18nc("@info", "Set up automatic system updates to keep your system secure and up to date. Click the button below to configure the update service.")

    function configureUpdates() {
        
        const command = "vanilla-updates-utility";

        Welcome.Utils.runCommand(command);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Item {
            Layout.fillHeight: true
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text:i18nc("@action:button", "Configure System Updates")
            icon.name: "system-software-update"
            onClicked: root.configureUpdates()
        }

        Item {
            Layout.fillHeight: true
        }
    }
}