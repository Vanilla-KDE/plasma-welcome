/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.plasma.welcome as Welcome
import org.kde.plasma.welcome.private as Private

Welcome.Page {
    id: root

    heading: i18nc("@title", "Welcome")
    description: xi18nc("@info:usagetip %1 is the name of the user's distro", "Welcome to Vanilla OS Kipferl! Let's set up your operating system.")

    actions: [
        Kirigami.Action {
            text: i18nc("@action:inmenu", "About Welcome Center")
            icon.name: "start-here-kde-plasma"
            onTriggered: pageStack.layers.push(aboutAppPage)
            displayHint: Kirigami.DisplayHint.AlwaysHide
        },
        Kirigami.Action {
            text: i18nc("@action:inmenu", "About KDE")
            icon.name: "kde"
            onTriggered: pageStack.layers.push(aboutKDEPage)
            displayHint: Kirigami.DisplayHint.AlwaysHide
        }
    ]

    Component {
        id: aboutKDEPage

        FormCard.AboutKDEPage {}
    }

    Component {
        id: aboutAppPage

        FormCard.AboutPage {}
    }

    topContent: [
        Kirigami.UrlButton {
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18nc("@action:button %1 is the name of the user's distro", "Learn more about %1", Welcome.Distro.name)
            url: Welcome.Distro.homeUrl
            visible: Welcome.Distro.homeUrl.length > 0
        }
    ]

    ColumnLayout {
        id: introImage

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Loader {
            id: imageContainer
            readonly property bool isImage:
                // Image path in the file
                Private.App.customIntroIcon.startsWith("file:/") ||
                // Our default image
                Private.App.customIntroIcon.length === 0

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.maximumWidth: root.width

            sourceComponent: isImage ? imageComponent : iconComponent

            Component {
                id: imageComponent

                Image {
                    id: image
                    source: "file:///usr/share/icons/hicolor/scalable/emblems/emblem-vanilla.svg"
                    fillMode: Image.PreserveAspectFit

                    Kirigami.PlaceholderMessage {
                        width: image.width
                        anchors.centerIn: parent
                        text: i18nc("@title", "Image loading failed")
                        explanation: xi18nc("@info:placeholder", "Could not load <filename>%1</filename>. Make sure it exists.", image.source)
                        visible: image.status == Image.Error
                    }
                }
            }

            Component {
                id: iconComponent

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.enormous * 2
                    implicitHeight: implicitWidth
                    source: Private.App.customIntroIcon || "kde"
                }
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: Math.round(Math.max(root.width / 2, imageContainer.implicitWidth / 2))
            text: Private.App.customIntroIconCaption || i18nc("@info", "Welcome to Vanilla OS community!")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
