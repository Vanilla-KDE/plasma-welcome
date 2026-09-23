/*
 * SPDX-FileCopyrightText: 2026 Fangcat_Dev <fangcat_dev@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.welcome as Welcome

import "apps.js" as AppsData

Welcome.Page {
    id: root

    heading: i18nc("@title", "Install apps")
    description: i18nc("@info", "Choose the apps you want to install. Expand each group to review the apps inside before continuing.")

    property var groups: []
    property var selectedApps: []
    property bool installing: false

    property var iconCache: ({})
    property var iconQueue: []
    property int activeIconRequests: 0
    readonly property int maxIconRequests: 5

    readonly property bool hasSelection: selectedApps.length > 0
    readonly property bool canGoBack: !installing
    readonly property bool canGoForward: !installing

    readonly property color cardBorderColor: Qt.rgba(
        Kirigami.Theme.textColor.r,
        Kirigami.Theme.textColor.g,
        Kirigami.Theme.textColor.b,
        0.25
    )

    function showLog(title, log) {
        logDialog.appName = title;
        logDialog.logText = log;
        logDialog.open();
    }

    function loadApps() {
        try {
            const parsed = AppsData.data;
            const loadedGroups = [];

            Object.keys(parsed).forEach(function(groupName) {
                const apps = parsed[groupName].map(function(app) {
                    return {
                        name: app.name,
                        id: app.id,
                        selected: app.active !== undefined ? !!app.active : true,
                        installStatus: "pending",
                        installLog: ""
                    };
                });

                loadedGroups.push({
                    name: normalizeGroupName(groupName),
                    key: groupName,
                    expanded: true,
                    apps: apps,
                    selectedCount: apps.filter(function(a) {
                        return a.selected;
                    }).length,
                    allSelected: apps.length > 0 && apps.every(function(a) {
                        return a.selected;
                    })
                });
            });

            root.groups = loadedGroups;
            refreshSelectedApps();

            for (let gi = 0; gi < root.groups.length; ++gi) {
                if (root.groups[gi].expanded)
                    root.requestIconsForGroup(gi);
            }
        } catch (error) {
            console.warn("Failed to load app list:", error);
            root.groups = [];
            root.selectedApps = [];
        }
    }

    function normalizeGroupName(name) {
        if (!name || name.length === 0)
            return i18nc("@label", "Apps");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function refreshSelectedApps() {
        const selected = [];
        const groups = root.groups.slice();

        for (let gi = 0; gi < groups.length; ++gi) {
            const group = Object.assign({}, groups[gi]);
            const apps = group.apps.slice();
            let count = 0;

            for (let ai = 0; ai < apps.length; ++ai) {
                const app = apps[ai];
                if (app.selected) {
                    selected.push({
                        name: app.name,
                        id: app.id,
                        groupIndex: gi,
                        appIndex: ai
                    });
                    ++count;
                }
            }

            group.selectedCount = count;
            group.allSelected = apps.length > 0 && count === apps.length;
            groups[gi] = group;
        }

        root.groups = groups;
        root.selectedApps = selected;
    }

    function updateApp(groupIndex, appIndex, changes) {
        if (groupIndex < 0 || groupIndex >= root.groups.length)
            return;

        const groups = root.groups.slice();
        const group = Object.assign({}, groups[groupIndex]);

        if (appIndex < 0 || appIndex >= group.apps.length)
            return;

        const apps = group.apps.slice();
        apps[appIndex] = Object.assign({}, apps[appIndex], changes);
        group.apps = apps;

        let selectedCount = 0;
        for (let i = 0; i < apps.length; ++i) {
            if (apps[i].selected)
                ++selectedCount;
        }

        group.selectedCount = selectedCount;
        group.allSelected = apps.length > 0 && selectedCount === apps.length;

        groups[groupIndex] = group;
        root.groups = groups;
    }

    function toggleGroup(groupIndex, checked) {
        if (groupIndex < 0 || groupIndex >= root.groups.length)
            return;

        const group = root.groups[groupIndex];
        const apps = group.apps.map(function(app) {
            return Object.assign({}, app, {
                selected: checked
            });
        });

        const groups = root.groups.slice();
        groups[groupIndex] = Object.assign({}, group, {
            apps: apps,
            selectedCount: checked ? apps.length : 0,
            allSelected: checked && apps.length > 0
        });

        root.groups = groups;
        refreshSelectedApps();
    }

    function toggleApp(groupIndex, appIndex, checked) {
        updateApp(groupIndex, appIndex, {
            selected: checked
        });
        refreshSelectedApps();
    }

    function toggleGroupExpanded(groupIndex) {
        if (groupIndex < 0 || groupIndex >= root.groups.length)
            return;

        const group = root.groups[groupIndex];
        const newExpanded = !group.expanded;

        const groups = root.groups.slice();
        groups[groupIndex] = Object.assign({}, group, {
            expanded: newExpanded
        });
        root.groups = groups;

        if (newExpanded)
            root.requestIconsForGroup(groupIndex);
    }

    function requestIconsForGroup(groupIndex) {
        if (groupIndex < 0 || groupIndex >= root.groups.length)
            return;

        const apps = root.groups[groupIndex].apps;
        for (let i = 0; i < apps.length; ++i)
            root.queueIconFetch(apps[i].id);
    }

    function queueIconFetch(appId) {
        if (!appId)
            return;
        if (root.iconCache[appId] !== undefined)
            return;
        if (root.iconQueue.indexOf(appId) !== -1)
            return;

        root.iconQueue.push(appId);
        pumpIconQueue();
    }

    function pumpIconQueue() {
        while (root.activeIconRequests < root.maxIconRequests
               && root.iconQueue.length > 0) {
            const appId = root.iconQueue.shift();
            if (root.iconCache[appId] !== undefined)
                continue;
            ++root.activeIconRequests;
            doFetchIcon(appId);
        }
    }

    function doFetchIcon(appId) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://flathub.org/api/v2/appstream/" + encodeURIComponent(appId));

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            --root.activeIconRequests;

            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const iconUrl = (data && data.icon) ? data.icon : "";

                    if (iconUrl) {
                        const cache = Object.assign({}, root.iconCache);
                        cache[appId] = iconUrl;
                        root.iconCache = cache;
                    } else {
                        console.warn("No icon URL found for", appId);
                    }
                } catch (error) {
                    console.warn("Parse icon error for", appId, error);
                }
            } else {
                console.warn("Unable to fetch icon for", appId, "status:", xhr.status);
            }

            root.pumpIconQueue();
        };

        xhr.send();
    }

    function continueToInstall() {
        if (!root.hasSelection || root.installing)
            return;

        root.installing = true;

        runSubsystem(function(success, log) {
            if (!success)
                notifySubsystemFailure(log);

            root.installing = false;
            root.startInstallation();
        });
    }

    function notifySubsystemFailure(log) {
        const win = applicationWindow();
        if (!win || !win.showPassiveNotification)
            return;

        win.showPassiveNotification(
            i18nc("@info", "System setup failed"),
            "long",
            i18nc("@action:button", "View log"),
            function() {
                root.showLog(subsystemCard.subsystemTitle, log);
            }
        );
    }

    function runSubsystem(onFinished) {
        const commands = subsystemCard.subsystemCommands;
        if (commands.length === 0) {
            subsystemCard.subsystemStatus = "installed";
            onFinished(true, "");
            return;
        }

        subsystemCard.subsystemStatus = "installing";
        subsystemCard.subsystemLog = "";

        runSubsystemCommand(commands, 0, onFinished);
    }

    // Welcome.Utils.runCommand() runs a single command without a shell, so
    // multiple lines are executed here one after another and stop on the first
    // failure, collecting every output into subsystemLog.
    function runSubsystemCommand(commands, index, onFinished) {
        if (index >= commands.length) {
            subsystemCard.subsystemStatus = "installed";
            onFinished(true, subsystemCard.subsystemLog);
            return;
        }

        const command = commands[index];
        appendSubsystemLog(i18nc("@info:shell", "$ %1", command));

        Welcome.Utils.runCommand(command, function(returnStatus, outputText) {
            if (outputText && outputText.length > 0)
                appendSubsystemLog(outputText);

            if (returnStatus !== 0) {
                subsystemCard.subsystemStatus = "failed";
                onFinished(false, subsystemCard.subsystemLog);
                return;
            }

            runSubsystemCommand(commands, index + 1, onFinished);
        });
    }

    function appendSubsystemLog(text) {
        subsystemCard.subsystemLog = subsystemCard.subsystemLog.length > 0
                ? subsystemCard.subsystemLog + "\n" + text
                : text;
    }

    function startInstallation() {
        if (!root.hasSelection || root.installing)
            return;

        root.installing = true;

        const selected = root.selectedApps.slice();
        for (let i = 0; i < selected.length; ++i) {
            updateApp(selected[i].groupIndex, selected[i].appIndex, {
                installStatus: "pending",
                installLog: ""
            });
        }

        installNext(0);
    }

    function installNext(index) {
        const selected = root.selectedApps;
        if (index >= selected.length) {
            root.installing = false;
            return;
        }

        const app = selected[index];
        const gi = app.groupIndex;
        const ai = app.appIndex;

        updateApp(gi, ai, { installStatus: "installing" });

        const command = "flatpak --user install -y " + app.id;

        Welcome.Utils.runCommand(command, function(returnStatus, outputText) {
            const success = (returnStatus === 0);

            updateApp(gi, ai, {
                installStatus: success ? "installed" : "failed",
                installLog: outputText
            });

            if (!success) {
                const win = applicationWindow();
                if (win && win.showPassiveNotification) {
                    win.showPassiveNotification(
                        i18nc("@info", "Failed to install %1", app.name),
                        "long",
                        i18nc("@action:button", "View log"),
                        function() {
                            root.showLog(app.name, outputText);
                        }
                    );
                }
            }

            root.installNext(index + 1);
        });
    }

    Component.onCompleted: loadApps()

    LogDialog {
        id: logDialog
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: root.hasSelection
                      ? i18nc("@info", "%1 app(s) selected", root.selectedApps.length)
                      : i18nc("@info", "No apps selected")
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            QQC2.Button {
                text: i18nc("@action:button", "Install selected")
                enabled: root.hasSelection && !root.installing
                onClicked: root.continueToInstall()
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                SubsystemCard {
                    id: subsystemCard
                    cardBorderColor: root.cardBorderColor
                    onLogRequested: function(title, log) {
                        root.showLog(title, log);
                    }
                }

                Repeater {
                    model: root.groups

                    delegate: GroupCard {
                        iconCache: root.iconCache
                        installing: root.installing
                        cardBorderColor: root.cardBorderColor
                        onGroupToggled: function(groupIndex, checked) {
                            root.toggleGroup(groupIndex, checked);
                        }
                        onGroupExpandToggled: function(groupIndex) {
                            root.toggleGroupExpanded(groupIndex);
                        }
                        onAppToggled: function(groupIndex, appIndex, checked) {
                            root.toggleApp(groupIndex, appIndex, checked);
                        }
                        onLogRequested: function(title, log) {
                            root.showLog(title, log);
                        }
                    }
                }
            }
        }
    }
}