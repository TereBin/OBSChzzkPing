#include "diagnostics.hpp"

#include "settings.hpp"

#include <QDateTime>
#include <QStringList>
#include <QSysInfo>

QString buildDiagnostics(const PluginSettings &settings, const QString &recentStatus,
                         const QString &obsVersion, const QString &appVersion)
{
  const auto enabledText = [](bool enabled)
  { return enabled ? QStringLiteral("켜짐") : QStringLiteral("꺼짐"); };
  const auto visibleText = [](bool visible)
  { return visible ? QStringLiteral("표시") : QStringLiteral("숨김"); };
  const QString color = QStringLiteral("#%1")
                            .arg(settings.discordEmbedColor & 0xffffff, 6, 16, QLatin1Char('0'))
                            .toUpper();

  QStringList lines;
  lines << QStringLiteral("OBSChzzkPing 진단 정보")
        << QStringLiteral("생성 시각: %1").arg(QDateTime::currentDateTime().toString(Qt::ISODate))
        << QStringLiteral("OBSChzzkPing: %1").arg(appVersion)
        << QStringLiteral("OBS: %1").arg(obsVersion)
        << QStringLiteral("Windows: %1").arg(QSysInfo::prettyProductName())
        << QStringLiteral("치지직 채널: %1")
               .arg(settings.channelId.isEmpty() ? QStringLiteral("없음")
                                                 : QStringLiteral("설정됨"))
        << QStringLiteral("Discord 자동 알림: %1").arg(enabledText(settings.discordEnabled))
        << QStringLiteral("Discord 연결: %1")
               .arg(isValidDiscordWebhook(settings.discordWebhook) ? QStringLiteral("연결됨")
                                                                   : QStringLiteral("연결 안 됨"))
        << QStringLiteral("Discord 연결 방식: %1")
               .arg(settings.discordManagedWebhook ? QStringLiteral("간편 연결")
                                                   : QStringLiteral("수동 또는 없음"))
        << QStringLiteral("Discord 역할: %1")
               .arg(settings.discordRoleName.isEmpty() ? QStringLiteral("없음")
                                                       : settings.discordRoleName)
        << QStringLiteral("Discord 임베드: %1 / 채널 %2 / 카테고리 %3 / 썸네일 %4")
               .arg(color, visibleText(settings.discordEmbedShowChannel),
                    visibleText(settings.discordEmbedShowCategory),
                    visibleText(settings.discordEmbedShowThumbnail))
        << QStringLiteral("X 작성 화면: %1").arg(enabledText(settings.xEnabled))
        << QStringLiteral("LIVE 확인: 첫 지연 %1초 / 간격 %2초 / 최대 %3초")
               .arg(settings.initialDelaySeconds)
               .arg(settings.pollingIntervalSeconds)
               .arg(settings.maximumWaitSeconds)
        << QStringLiteral("자동 업데이트 확인: %1").arg(enabledText(settings.automaticUpdateChecks))
        << QStringLiteral("최근 상태: %1")
               .arg(recentStatus.trimmed().isEmpty() ? QStringLiteral("없음")
                                                     : recentStatus.trimmed());
  return lines.join(QLatin1Char('\n'));
}
