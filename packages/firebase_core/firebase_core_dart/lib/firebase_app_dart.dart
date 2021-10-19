part of firebase_core_dart;

/// A Dart only implementation of a Firebase app instance.
class FirebaseApp {
  FirebaseApp._(this._core, this._name, this._options);

  final FirebaseCore _core;
  final String _name;
  final FirebaseOptions _options;
  bool _isAutomaticDataCollectionEnabled = false;

  Future<void> delete() async {
    _core._apps.remove(_name);
  }

  bool get isAutomaticDataCollectionEnabled =>
      _isAutomaticDataCollectionEnabled;

  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    _isAutomaticDataCollectionEnabled = enabled;
    return Future.value();
  }

  /// Sets whether automatic resource management is enabled or disabled.
  /// This has no affect on Da.
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return Future.value();
  }
}
