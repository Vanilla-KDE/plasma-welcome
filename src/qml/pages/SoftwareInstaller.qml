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
import org.kde.plasma.welcome.private as Private

Welcome.Page {
    id: root

    heading: i18nc("@title", "Install apps")
    description: i18nc("@info", "Choose the apps you want to install or remove. Expand each group to review the apps inside before continuing.")

    // ---------------------------------------------------------------
    // State
    // ---------------------------------------------------------------
    property var groups: []
    property var selectedApps: []
    property var subsystemCommands: []
    property bool installing: false

    readonly property bool hasSelection: selectedApps.length > 0
    readonly property bool hasInstallSelection: selectedApps.some(function(app) {
        return !app.remove;
    })
    readonly property bool hasRemoveSelection: selectedApps.some(function(app) {
        return app.remove;
    })
    readonly property bool canGoBack: !installing
    readonly property bool canGoForward: !installing

    readonly property string selectionLabel: hasSelection
            ? i18nc("@info", "%1 app(s) selected", selectedApps.length)
            : i18nc("@info", "No apps selected")

    readonly property string actionLabel: {
        if (hasInstallSelection && hasRemoveSelection)
            return i18nc("@action:button", "Apply selected");
        if (hasRemoveSelection)
            return i18nc("@action:button", "Remove selected");
        return i18nc("@action:button", "Install selected");
    }

    AppIconProvider {
        id: iconProvider
    }

    readonly property color cardBorderColor: Qt.rgba(
        Kirigami.Theme.textColor.r,
        Kirigami.Theme.textColor.g,
        Kirigami.Theme.textColor.b,
        0.25
    )

    // The list is centered instead of stretching across the whole page.
    readonly property int listWidth: Kirigami.Units.gridUnit * 32

    function showLog(title, log) {
        logDialog.appName = title;
        logDialog.logText = log;
        logDialog.open();
    }

    // ---------------------------------------------------------------
    // Notifications
    // ---------------------------------------------------------------
    function notify(message) {
        const win = applicationWindow();
        if (win && win.showPassiveNotification)
            win.showPassiveNotification(message);
    }

    function notifyFailure(message, title, log) {
        const win = applicationWindow();
        if (!win || !win.showPassiveNotification)
            return;

        win.showPassiveNotification(
            message,
            "long",
            i18nc("@action:button", "View log"),
            function() {
                root.showLog(title, log);
            }
        );
    }

    // ---------------------------------------------------------------
    // Loading the app list
    // ---------------------------------------------------------------
    function loadApps() {
        const raw = Private.App.appsData;
        if (!raw) {
            console.warn("Failed to load app list from", Private.App.appsDataFile);
            resetState();
            return;
        }

        let parsed;
        try {
            parsed = JSON.parse(raw);
        } catch (error) {
            console.warn("Failed to load app list:", error);
            resetState();
            return;
        }

        root.subsystemCommands = subsystemCommandsFrom(parsed);

        // The "deprecated" group only offers installed apps for removal, so it
        // can only be built once the installed apps are known.
        listInstalledApps(function(installedApps) {
            root.groups = buildGroups(parsed, installedApps);
            refreshSelectedApps();
        });
    }

    function resetState() {
        root.groups = [];
        root.selectedApps = [];
        root.subsystemCommands = [];
    }

    function subsystemCommandsFrom(parsed) {
        const commands = parsed.subsystem && parsed.subsystem.commands;
        return Array.isArray(commands) ? commands : [];
    }

    // Reports every Flatpak app installed for the user as `{ appId: true }`.
    function listInstalledApps(callback) {
        Welcome.Utils.runCommand("flatpak list --app --columns=application", function(status, output) {
            const installed = {};

            if (status === 0 && output) {
                const lines = output.split("\n");
                for (let i = 0; i < lines.length; ++i) {
                    const appId = lines[i].trim();
                    if (appId.length > 0)
                        installed[appId] = true;
                }
            }

            callback(installed);
        });
    }

    function buildGroups(parsed, installedApps) {
        const groups = Object.keys(parsed)
            .filter(function(key) {
                // `subsystem` holds the setup commands and `deprecated` is
                // built separately, so neither is a regular app group.
                return key !== "subsystem"
                        && key !== "deprecated"
                        && Array.isArray(parsed[key]);
            })
            .map(function(key) {
                return createGroup(key, parsed[key], false);
            });

        // Only offer apps that are currently installed for removal; when none
        // of them is installed, the group is not shown at all.
        const deprecatedApps = Array.isArray(parsed.deprecated)
                ? parsed.deprecated.filter(function(app) {
                    return app && installedApps[app.id];
                })
                : [];

        if (deprecatedApps.length > 0)
            groups.push(createGroup("deprecated", deprecatedApps, true));

        return groups;
    }

    // Turns one apps.json section into the group object the cards render.
    function createGroup(groupName, appList, deprecated) {
        const apps = appList.map(function(app) {
            return {
                name: app.name,
                id: app.id,
                // Removals are opt-in so installed apps are never removed by
                // accident, while regular groups are selected by default.
                selected: app.active !== undefined ? !!app.active : !deprecated,
                installStatus: "pending",
                installLog: ""
            };
        });

        return recountGroup({
            name: groupName === "deprecated"
                ? i18nc("@label", "Deprecated")
                : normalizeGroupName(groupName),
            key: groupName,
            deprecated: deprecated,
            expanded: false,
            apps: apps
        });
    }

    function normalizeGroupName(name) {
        if (!name || name.length === 0)
            return i18nc("@label", "Apps");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    // ---------------------------------------------------------------
    // Group and app state
    // ---------------------------------------------------------------
    // Returns a copy of `group` with its selection counters recomputed.
    function recountGroup(group) {
        let count = 0;
        for (let i = 0; i < group.apps.length; ++i) {
            if (group.apps[i].selected)
                ++count;
        }

        return Object.assign({}, group, {
            selectedCount: count,
            allSelected: group.apps.length > 0 && count === group.apps.length
        });
    }

    // Rebuilds the flat list of selected apps and keeps the group counters in
    // sync with it.
    function refreshSelectedApps() {
        const selected = [];

        root.groups = root.groups.map(function(group, groupIndex) {
            const counted = recountGroup(group);

            counted.apps.forEach(function(app, appIndex) {
                if (!app.selected)
                    return;

                selected.push({
                    name: app.name,
                    id: app.id,
                    groupIndex: groupIndex,
                    appIndex: appIndex,
                    remove: group.deprecated === true
                });
            });

            return counted;
        });

        root.selectedApps = selected;
    }

    function updateApp(groupIndex, appIndex, changes) {
        const group = root.groups[groupIndex];
        if (!group || !group.apps[appIndex])
            return;

        const apps = group.apps.slice();
        apps[appIndex] = Object.assign({}, apps[appIndex], changes);

        const groups = root.groups.slice();
        groups[groupIndex] = recountGroup(Object.assign({}, group, {
            apps: apps
        }));
        root.groups = groups;
    }

    function toggleGroup(groupIndex, checked) {
        const group = root.groups[groupIndex];
        if (!group)
            return;

        const apps = group.apps.map(function(app) {
            return Object.assign({}, app, {
                selected: checked
            });
        });

        const groups = root.groups.slice();
        groups[groupIndex] = recountGroup(Object.assign({}, group, {
            apps: apps
        }));
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
        const group = root.groups[groupIndex];
        if (!group)
            return;

        const expanded = !group.expanded;

        const groups = root.groups.slice();
        groups[groupIndex] = Object.assign({}, group, {
            expanded: expanded
        });
        root.groups = groups;

        // Icons are only fetched once the group is opened.
        if (expanded)
            iconProvider.requestForApps(group.apps);
    }

    // ---------------------------------------------------------------
    // System setup ("subsystem" commands)
    // ---------------------------------------------------------------
    function continueToInstall() {
        if (!root.hasSelection || root.installing)
            return;

        root.installing = true;

        runSubsystem(function(success, log) {
            if (!success)
                notifyFailure(i18nc("@info", "System setup failed"),
                              subsystemCard.subsystemTitle, log);

            // The subsystem phase is over; the app phase manages the flag.
            root.installing = false;
            root.applySelection();
        });
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

    // Welcome.Utils.runCommand() runs a single command without a shell, so the
    // commands are executed one after another and stop at the first failure,
    // collecting every output into subsystemLog.
    function runSubsystemCommand(commands, index, onFinished) {
        if (index >= commands.length) {
            subsystemCard.subsystemStatus = "installed";
            onFinished(true, subsystemCard.subsystemLog);
            return;
        }

        const command = commands[index];
        appendSubsystemLog(i18nc("@info:shell", "$ %1", command));

        Welcome.Utils.runCommand(command, function(status, output) {
            if (output && output.length > 0)
                appendSubsystemLog(output);

            if (status !== 0) {
                subsystemCard.subsystemStatus = "failed";
                onFinished(false, subsystemCard.subsystemLog);
                return;
            }

            runSubsystemCommand(commands, index + 1, onFinished);
        });
    }

    function appendSubsystemLog(text) {
        const log = subsystemCard.subsystemLog;
        subsystemCard.subsystemLog = log.length > 0 ? log + "\n" + text : text;
    }

    // ---------------------------------------------------------------
    // Installing and removing apps
    // ---------------------------------------------------------------
    function applySelection() {
        if (!root.hasSelection || root.installing)
            return;

        root.installing = true;

        const installs = [];
        const removals = [];

        root.selectedApps.forEach(function(app) {
            updateApp(app.groupIndex, app.appIndex, {
                installStatus: "pending",
                installLog: ""
            });

            (app.remove ? removals : installs).push(app);
        });

        // Install first so a failing install never blocks the removals.
        runOperation(installs.concat(removals), 0);
    }

    // Runs the queue one app at a time, since runCommand() only handles a
    // single command.
    function runOperation(operations, index) {
        if (index >= operations.length) {
            root.finishInstallation();
            return;
        }

        const app = operations[index];
        const install = !app.remove;

        updateApp(app.groupIndex, app.appIndex, { installStatus: "installing" });

        const command = (install ? "flatpak --user install -y " : "flatpak uninstall -y ") + app.id;

        Welcome.Utils.runCommand(command, function(status, output) {
            const success = (status === 0);

            updateApp(app.groupIndex, app.appIndex, {
                installStatus: success ? (install ? "installed" : "removed") : "failed",
                installLog: output
            });

            if (!success) {
                notifyFailure(install
                              ? i18nc("@info", "Failed to install %1", app.name)
                              : i18nc("@info", "Failed to remove %1", app.name),
                              app.name, output);
            } else if (!install) {
                notify(i18nc("@info", "Removed %1", app.name));
            }

            runOperation(operations, index + 1);
        });
    }

    function finishInstallation() {
        root.installing = false;

        // Removed apps no longer belong to the deprecated group, which only
        // exists for installed apps, so drop the group once it is empty.
        root.groups = root.groups
            .map(function(group) {
                if (!group.deprecated)
                    return group;

                const apps = group.apps.filter(function(app) {
                    return app.installStatus !== "removed";
                });

                if (apps.length === 0)
                    return null;

                return recountGroup(Object.assign({}, group, {
                    apps: apps
                }));
            })
            .filter(function(group) {
                return group !== null;
            });

        refreshSelectedApps();
    }

    Component.onCompleted: loadApps()

    LogDialog {
        id: logDialog
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, root.listWidth)
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: root.selectionLabel
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            QQC2.Button {
                text: root.actionLabel
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
                    subsystemCommand: root.subsystemCommands
                    cardBorderColor: root.cardBorderColor
                    onLogRequested: function(title, log) {
                        root.showLog(title, log);
                    }
                }

                Repeater {
                    model: root.groups

                    delegate: GroupCard {
                        iconCache: iconProvider.cache
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