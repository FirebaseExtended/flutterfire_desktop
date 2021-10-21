part of firebase_core_dart;

/// Entry point of Firebase Core for dart-only apps.
class Firebase {
  // Ensures end-users cannot initialize the class.
  Firebase._();

  static final _delegate = _FirebaseCoreDelegate();

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// If no name is passed, the options will be considered as the DEFAULT app.
  static Future<FirebaseApp> initializeApp({
    String? name,
    required FirebaseOptions? options,
  }) async {
    return _delegate._initializeApp(
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
  List<FirebaseApp> get apps {
    return _delegate.apps;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Firebase) {
      return false;
    }
    return other.hashCode == hashCode;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$Firebase';
}
