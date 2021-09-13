library firebase_core_dart;

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

part 'firebase_app_dart.dart';

class FirebaseCoreDart extends FirebasePlatform {
  /// Registers that [FirebaseCoreWeb] is the platform implementation.
  static void registerWith(Registrar registrar) {
    FirebasePlatform.instance = FirebaseCoreDart();
  }

  Map<String, FirebaseAppPlatform> _apps =
      new Map<String, FirebaseAppPlatform>();

  @override
  List<FirebaseAppPlatform> get apps {
    return _apps.values.toList(growable: false);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String? name, FirebaseOptions? options}) async {
    // TODO how should this be handled?
    assert(options != null);

    String _name = name ?? defaultFirebaseAppName;

    if (_apps.containsKey(_name)) {
      throw duplicateApp(_name);
    }

    FirebaseAppPlatform _app = FirebaseAppDart._(this, _name, options!);

    _apps[_name] = _app;
    return _app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }
}
