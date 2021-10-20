part of firebase_core_dart;

/// The default Firebase application name.
const String defaultFirebaseAppName = '[DEFAULT]';

/// Dart-only implementation of FirebaseCore for managing Firebase app
/// instances.
class FirebaseCore {
  final Map<String, FirebaseApp> _apps = <String, FirebaseApp>{};

  List<FirebaseApp> get apps {
    return _apps.values.toList(growable: false);
  }

  Future<FirebaseApp> initializeApp({
    String name = defaultFirebaseAppName,
    required FirebaseOptions? options,
  }) async {
    if (_apps.containsKey(name)) {
      throw duplicateApp(name);
    }

    final _app = FirebaseApp._(this, name, options!);

    _apps[name] = _app;
    return _app;
  }

  @override
  FirebaseApp app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }
}
