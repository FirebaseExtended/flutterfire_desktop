#ifndef FLUTTER_PLUGIN_FIREBASE_STORAGE_DESKTOP_PLUGIN_H_
#define FLUTTER_PLUGIN_FIREBASE_STORAGE_DESKTOP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace firebase_storage_desktop {

class FirebaseStorageDesktopPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FirebaseStorageDesktopPlugin();

  virtual ~FirebaseStorageDesktopPlugin();

  // Disallow copy and assign.
  FirebaseStorageDesktopPlugin(const FirebaseStorageDesktopPlugin&) = delete;
  FirebaseStorageDesktopPlugin& operator=(const FirebaseStorageDesktopPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace firebase_storage_desktop

#endif  // FLUTTER_PLUGIN_FIREBASE_STORAGE_DESKTOP_PLUGIN_H_
