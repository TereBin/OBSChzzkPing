#pragma once

class QJsonObject;
class QString;
class QWidget;

void showDiscordPreviewDialog(QWidget *parent, const QJsonObject &payload, bool usedFallback);
void showTextPreviewDialog(QWidget *parent, const QString &title, const QString &text);
