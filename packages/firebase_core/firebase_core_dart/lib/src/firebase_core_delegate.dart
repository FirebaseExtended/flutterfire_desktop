part of firebase_core_dart;

/// An internal delegate to perform all Firebase core functionalities.
class _FirebaseCoreDelegate {
  final Map<String, FirebaseApp> _apps = <String, FirebaseApp>{};

  Future<FirebaseApp> _initializeApp({
    String? name,
    required FirebaseOptions? options,
  }) async {
    final _name = name ?? defaultFirebaseAppName;

    if (_apps.containsKey(name)) {
      throw duplicateApp(name!);
    }

    final _app = FirebaseApp._(this, _name, options!);

    _apps[_name] = _app;
    return _app;
  }

  FirebaseApp _app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }
}
