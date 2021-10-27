part of firebase_core_dart;

/// Entry point of Firebase Core for dart-only apps.
class Firebase {
  // Ensures end-users cannot initialize the class.
  Firebase._();

  ///
  @visibleForTesting
  static FirebaseCoreDelegate? delegatePackingProperty;

  static FirebaseCoreDelegate get _delegate =>
      delegatePackingProperty ?? FirebaseCoreDelegate._instance;

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// If no name is passed, the options will be considered as the DEFAULT app.
  static Future<FirebaseApp> initializeApp({
    String? name,
    required FirebaseOptions options,
  }) async {
    return _delegate.initializeApp(
      name: name,
      options: options,
    );
  }

  /// Returns a [FirebaseApp] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
  static FirebaseApp app([String name = defaultFirebaseAppName]) {
    return _delegate.app(name);
  }

  /// Returns a list of all [FirebaseApp] instances that have been created.
  static List<FirebaseApp> get apps {
    return _delegate.apps;
  }
}
