#include "include/firebase_auth_desktop/firebase_auth_desktop_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace {

class FirebaseAuthDesktopPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FirebaseAuthDesktopPlugin();

  virtual ~FirebaseAuthDesktopPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void FirebaseAuthDesktopPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "firebase_auth_desktop",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FirebaseAuthDesktopPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FirebaseAuthDesktopPlugin::FirebaseAuthDesktopPlugin() {}

FirebaseAuthDesktopPlugin::~FirebaseAuthDesktopPlugin() {}

void FirebaseAuthDesktopPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void FirebaseAuthDesktopPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FirebaseAuthDesktopPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
