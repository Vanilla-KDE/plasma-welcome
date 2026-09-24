/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *  SPDX-FileCopyrightText: 2024 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

#include <KAuthorized>
#include <KDesktopFile>
#include <KOSRelease>
#include <KPluginMetaData>

#include "config-plasma-welcome.h"

#include "app.h"
#include "welcome_debug.h"

App::App(QObject *parent)
    : QObject(parent)
{
    m_mode = Mode::Welcome;

    // Welcome page customisation
    m_customIntroText = QString();
    m_customIntroIcon = QString();
    m_customIntroIconCaption = QString();

    const QFileInfo introTextFile = QFileInfo(QStringLiteral(DISTRO_CUSTOM_INTRO_FILE));
    if (introTextFile.exists()) {
        const KDesktopFile desktopFile(introTextFile.absoluteFilePath());
        m_customIntroText = desktopFile.readName();
        m_customIntroIcon = desktopFile.readIcon();
        m_customIntroIconLink = desktopFile.readUrl();
        m_customIntroIconCaption = desktopFile.readComment();
    }
}

void App::setMode(App::Mode mode)
{
    m_mode = mode;
}

void App::setPages(const QStringList &pages)
{
    m_pages = pages;
}

QString App::installPrefix() const
{
    return QString::fromLatin1(PLASMA_WELCOME_INSTALL_DIR);
}

QString App::distroPagesDir() const
{
    return QString::fromLatin1(DISTRO_CUSTOM_PAGE_FOLDER);
}

QStringList App::distroPages() const
{
    const QString dirname = QStringLiteral(DISTRO_CUSTOM_PAGE_FOLDER);
    const QDir distroPageDir = QDir(dirname);

    if (!distroPageDir.exists() || distroPageDir.isEmpty()) {
        return {};
    }

    QStringList pages = distroPageDir.entryList(QDir::NoDotAndDotDot | QDir::Files | QDir::Readable, QDir::Name);
    for (QString &page : pages) {
        page = QStringLiteral("file://") + dirname + page;
    }

    return pages;
}

QString App::appsDataFile() const
{
    QStringList candidates;

    const QString overrideFile = qEnvironmentVariable("PLASMA_WELCOME_APPS_FILE");
    if (!overrideFile.isEmpty()) {
        candidates.append(overrideFile);
    }

    candidates.append(QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, QStringLiteral("plasma/plasma-welcome/apps.json")));

    candidates.append(QString::fromLatin1(APPS_DATA_FILE));

    for (const QString &candidate : candidates) {
        if (QFileInfo::exists(candidate)) {
            return candidate;
        }
    }

    return QStringLiteral(":/org/kde/plasma/welcome/apps.json");
}

QString App::appsData() const
{
    const QString path = appsDataFile();

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qCWarning(WELCOME_LOG) << "Failed to open the app list" << path << file.errorString();
        return QString();
    }

    qCDebug(WELCOME_LOG) << "Using the app list from" << path;
    return QString::fromUtf8(file.readAll());
}

// Workaround for lack of appstream info in snaps for advertised items on Discover page
bool App::isDistroSnapOnly() const
{
    return KOSRelease().extraValue("UBUNTU_VARIANT") == QStringLiteral("core");
}

bool App::kcmAvailable(const QString &kcm) const
{
    KPluginMetaData data(QStringLiteral("plasma/kcms/systemsettings/%1").arg(kcm));
    return data.isValid() && KAuthorized::authorizeControlModule(kcm + QLatin1String(".desktop"));
}

#include "moc_app.cpp"
