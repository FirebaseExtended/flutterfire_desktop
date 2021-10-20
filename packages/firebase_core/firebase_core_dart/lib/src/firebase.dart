part of firebase_core_dart;

/// The default Firebase application name.
const String defaultFirebaseAppName = '[DEFAULT]';

class Firebase {
  Firebase._();

  static final _delegate = FirebaseCore();

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// The default app instance cannot be initialized here and should be created
  /// using the platform Firebase integration.
  static Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final app = await _delegate.initializeApp(
      name: name,
      options: options,
    );

    return app;
  }
}

/// Dart-only implementation of FirebaseCore for managing Firebase app
/// instances.
class FirebaseCore {
  final Map<String, FirebaseApp> _apps = <String, FirebaseApp>{};

  List<FirebaseApp> get apps {
    return _apps.values.toList(growable: false);
  }

  Future<FirebaseApp> initializeApp({
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

  @override
  FirebaseApp app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }
}
