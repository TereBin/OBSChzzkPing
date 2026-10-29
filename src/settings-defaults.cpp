#include "settings.hpp"

QString defaultDiscordMessageTemplate()
{
  return QString::fromUtf8("🔴 {channel} 방송 시작!\n\n{title}\n카테고리: {category}\n{url}");
}

QString defaultXMessageTemplate()
{
  return QString::fromUtf8("🔴 {channel} 방송 시작!\n\n{title}\n{category}\n{url}");
}
