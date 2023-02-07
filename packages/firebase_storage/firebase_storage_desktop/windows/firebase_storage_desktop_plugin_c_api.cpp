#include "include/firebase_storage_desktop/firebase_storage_desktop_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "firebase_storage_desktop_plugin.h"

void FirebaseStorageDesktopPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  firebase_storage_desktop::FirebaseStorageDesktopPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
