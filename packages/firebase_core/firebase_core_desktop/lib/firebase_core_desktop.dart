library firebase_core_desktop;

import 'package:firebase_core_dart/firebase_core.dart' as core_dart;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

part 'firebase_app_desktop.dart';

/// Desktop implementation of FirebaseCore for managing Firebase app
/// instances.
class FirebaseCore extends FirebasePlatform {
  /// Called by PluginRegistry to register this plugin as the implementation for Desktop
  static void registerWith() {
    FirebasePlatform.instance = FirebaseCore();
  }

  core_dart.FirebaseCore _core = core_dart.FirebaseCore();

  final Map<String, FirebaseAppPlatform> _apps =
      <String, FirebaseAppPlatform>{};

  @override
  List<FirebaseAppPlatform> get apps {
    return _apps.values.toList(growable: false);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final _dartOptions = core_dart.FirebaseOptions.fromMap(options!.asMap);
    final _dartApp = await _core.initializeApp(options: _dartOptions);
    final FirebaseAppPlatform _app =
        FirebaseApp._(this, _dartApp.name, options);

    _apps[_dartApp.name] = _app;
    return FirebaseApp._(this, _dartApp.name, options);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }
}
