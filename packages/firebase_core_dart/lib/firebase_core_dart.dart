library firebase_core_dart;

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

part 'firebase_app_dart.dart';

/// A Dart only implementation of FirebaseCore for managing Firebase app
/// instances.
class FirebaseCoreDart extends FirebasePlatform {
  /// Registers that [FirebaseCoreDart] is the platform implementation.
  static void registerWith(Registrar registrar) {
    FirebasePlatform.instance = FirebaseCoreDart();
  }

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
    // TODO how should this be handled?
    assert(options != null);

    final _name = name ?? defaultFirebaseAppName;

    if (_apps.containsKey(_name)) {
      throw duplicateApp(_name);
    }

    final FirebaseAppPlatform _app = FirebaseAppDart._(this, _name, options!);

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
