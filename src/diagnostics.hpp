#pragma once

#include <QString>

struct PluginSettings;

QString buildDiagnostics(const PluginSettings &settings, const QString &recentStatus,
                         const QString &obsVersion, const QString &streamPingVersion);
