#include "notifier.hpp"

#include <obs-frontend-api.h>
#include <obs-module.h>

#include <QAction>
#include <QMainWindow>
#include <QPointer>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("streamping", "ko-KR")

namespace
{
QPointer<StreamNotifier> g_notifier;
QPointer<QAction> g_settingsAction;

void cleanupQtObjects()
{
  delete g_settingsAction.data();
  delete g_notifier.data();
  g_settingsAction.clear();
  g_notifier.clear();
}

void onFrontendEvent(enum obs_frontend_event event, void *)
{
  if (event == OBS_FRONTEND_EVENT_EXIT)
  {
    cleanupQtObjects();
    return;
  }

  if (!g_notifier)
    return;

  switch (event)
  {
  case OBS_FRONTEND_EVENT_STREAMING_STARTED:
    g_notifier->onStreamingStarted();
    break;
  case OBS_FRONTEND_EVENT_STREAMING_STOPPED:
    g_notifier->onStreamingStopped();
    break;
  default:
    break;
  }
}
} // namespace

MODULE_EXPORT const char *obs_module_description(void)
{
  return "Sends a Discord notification after a CHZZK stream becomes live.";
}

MODULE_EXPORT const char *obs_module_name(void) { return "OBSChzzkPing"; }

bool obs_module_load(void)
{
  auto *mainWindow = static_cast<QMainWindow *>(obs_frontend_get_main_window());
  g_notifier = new StreamNotifier(mainWindow);

  g_settingsAction =
      static_cast<QAction *>(obs_frontend_add_tools_menu_qaction("OBSChzzkPing 설정"));
  QObject::connect(g_settingsAction, &QAction::triggered, g_notifier,
                   &StreamNotifier::showSettings);
  obs_frontend_add_event_callback(onFrontendEvent, nullptr);

  blog(LOG_INFO, "[OBSChzzkPing] Plugin loaded (version %s)", STREAMPING_VERSION);
  return true;
}

void obs_module_unload(void)
{
  obs_frontend_remove_event_callback(onFrontendEvent, nullptr);

  // Normally cleaned during OBS_FRONTEND_EVENT_EXIT while the Qt parents are
  // still alive. QPointer also makes this safe for late or direct unloading.
  cleanupQtObjects();
  blog(LOG_INFO, "[OBSChzzkPing] Plugin unloaded");
}
