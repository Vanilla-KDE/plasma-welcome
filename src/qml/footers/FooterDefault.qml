/*
 *  SPDX-FileCopyrightText: 2023 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    spacing: Kirigami.Units.smallSpacing

    readonly property bool inLayer: pageStack.layers.depth > 1
    readonly property bool atStart: pageStack.currentIndex === 0
    readonly property bool atEnd: pageStack.currentIndex === pageStack.depth - 1

    readonly property var currentPage: pageStack.currentItem

    readonly property bool canGoBack: {
        if (root.inLayer)
            return true;
        if (!root.currentPage)
            return !root.atStart;
        if (root.currentPage.canGoBack !== undefined)
            return root.currentPage.canGoBack;
        return !root.atStart;
    }

    readonly property bool canGoForward: {
        if (root.inLayer)
            return false;
        if (!root.currentPage)
            return !root.atEnd;
        if (root.currentPage.canGoForward !== undefined)
            return root.currentPage.canGoForward;
        return !root.atEnd;
    }

    QQC2.Button {
        Layout.alignment: Qt.AlignLeft

        action: Kirigami.Action {
            readonly property bool isSkip: root.atStart && !root.inLayer

            text: isSkip ? i18nc("@action:button", "&Skip") : i18nc("@action:button", "&Back")
            icon.name: {
                if (isSkip) {
                    return "dialog-cancel-symbolic";
                } else if (Qt.application.layoutDirection === Qt.LeftToRight) {
                    return "go-previous-symbolic";
                } else {
                    return "go-previous-rtl-symbolic";
                }
            }
            shortcut: Qt.application.layoutDirection === Qt.LeftToRight ? "Left" : "Right"
            enabled: root.canGoBack

            onTriggered: {
                if (root.inLayer) {
                    pageStack.layers.pop();
                } else if (!root.atStart) {
                    pageStack.currentIndex -= 1;
                } else {
                    Qt.quit();
                }
            }
        }
    }

    QQC2.PageIndicator {
        Layout.alignment: Qt.AlignHCenter

        enabled: !root.inLayer
        count: pageStack.depth
        currentIndex: pageStack.currentIndex
        onCurrentIndexChanged: pageStack.currentIndex = currentIndex
        interactive: true
    }

    QQC2.Button {
        id: nextButton
        Layout.alignment: Qt.AlignRight
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.LeftToRight ? !root.atEnd : root.atEnd

        action: Kirigami.Action {
            text: root.atEnd ? i18nc("@action:button", "&Finish") : i18nc("@action:button", "&Next")
            icon.name: {
                if (root.atEnd) {
                    return "dialog-ok-apply-symbolic";
                } else if (Qt.application.layoutDirection === Qt.LeftToRight) {
                    return "go-next-symbolic";
                } else {
                    return "go-next-rtl-symbolic";
                }
            }
            shortcut: Qt.application.layoutDirection === Qt.LeftToRight ? "Right" : "Left"
            enabled: root.canGoForward

            onTriggered: {
                if (!root.atEnd) {
                    pageStack.currentIndex += 1;
                } else {
                    Qt.quit();
                }
            }
        }
    }
}