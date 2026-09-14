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
            id: plasmaLink
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18nc("@action:button", "Learn more about Vanilla OS")
            url: "https://vanillaos.org"
        },
        Kirigami.UrlButton {
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18nc("@action:button %1 is the name of the user's distro", "Learn more about %1", Welcome.Distro.name)
            url: Welcome.Distro.homeUrl
            visible: Welcome.Distro.homeUrl.length > 0
        }
    ]

    QQC2.AbstractButton {
        id: konqiButton

        anchors.centerIn: parent
        height: Math.min(root.height, Kirigami.Units.gridUnit * 17)

        property string url: Private.App.customIntroIconLink || plasmaLink.url

        onClicked: Qt.openUrlExternally(url)

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Loader {
                id: imageContainer

                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.maximumWidth: root.width

                sourceComponent: imageComponent

                Component {
                    id: imageComponent

                    Image {
                        id: image
                        source: "file:///usr/share/icons/hicolor/scalable/emblems/emblem-vanilla.svg"
                        fillMode: Image.PreserveAspectFit

                        Kirigami.PlaceholderMessage {
                            width: root.width - (Kirigami.Units.largeSpacing * 4)
                            anchors.centerIn: parent
                            text: i18nc("@title", "Image loading failed")
                            explanation: xi18nc("@info:placeholder", "Could not load <filename>%1</filename>. Make sure it exists.", Private.App.customIntroIcon)
                            visible: image.status == Image.Error
                        }
                    }
                }

                HoverHandler {
                    id: hoverhandler
                    cursorShape: Qt.PointingHandCursor
                }

                QQC2.ToolTip {
                    visible: hoverhandler.hovered
                    text: i18nc("@action:button clicking on this takes the user to a web page", "Visit %1", konqiButton.url)
                }
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: Math.round(Math.max(root.width / 2, imageContainer.implicitWidth / 2))
                text: konqiButton.text
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
