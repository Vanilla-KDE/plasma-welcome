/*
 * SPDX-FileCopyrightText: 2026 Fangcat_Dev <fangcat_dev@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick

// Fetches app icons from Flathub on demand and caches them by app ID, so the
// installer page only has to hand `cache` to the cards.
QtObject {
    id: iconProvider

    // appId -> icon URL
    property var cache: ({})
    property var queue: []
    property int activeRequests: 0
    readonly property int maxRequests: 5

    function requestForApps(apps) {
        for (let i = 0; i < apps.length; ++i)
            request(apps[i].id);
    }

    function request(appId) {
        if (!appId)
            return;
        if (cache[appId] !== undefined)
            return;
        if (queue.indexOf(appId) !== -1)
            return;

        queue.push(appId);
        pump();
    }

    function pump() {
        while (activeRequests < maxRequests && queue.length > 0) {
            const appId = queue.shift();
            if (cache[appId] !== undefined)
                continue;

            ++activeRequests;
            fetch(appId);
        }
    }

    function fetch(appId) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://flathub.org/api/v2/appstream/" + encodeURIComponent(appId));

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            --iconProvider.activeRequests;
            handleResponse(appId, xhr);
            iconProvider.pump();
        };

        xhr.send();
    }

    function handleResponse(appId, xhr) {
        if (xhr.status !== 200) {
            console.warn("Unable to fetch icon for", appId, "status:", xhr.status);
            return;
        }

        let iconUrl = "";
        try {
            const data = JSON.parse(xhr.responseText);
            iconUrl = (data && data.icon) ? data.icon : "";
        } catch (error) {
            console.warn("Parse icon error for", appId, error);
            return;
        }

        if (!iconUrl) {
            console.warn("No icon URL found for", appId);
            return;
        }

        const updated = Object.assign({}, iconProvider.cache);
        updated[appId] = iconUrl;
        iconProvider.cache = updated;
    }
}
