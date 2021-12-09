// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of firebase_core_dart;

/// A Dart only implementation of a Firebase app instance.
class FirebaseApp {
  FirebaseApp._(this._delegate);
  final _FirebaseAppDelegete _delegate;

  /// Deletes this app and frees up system resources.
  ///
  /// Once deleted, any plugin functionality using this app instance will throw
  /// an error.
  void delete() {
    _delegate.delete();
  }

  /// The name of this [FirebaseApp].
  String get name => _delegate.name;

  /// The [FirebaseOptions] this app was created with.
  FirebaseOptions get options => _delegate.options;

  /// Returns true if automatic data collection is enabled for this app.
  bool get isAutomaticDataCollectionEnabled =>
      _delegate.isAutomaticDataCollectionEnabled;

  /// Sets whether automatic data collection is enabled or disabled for this app.
  ///
  /// It is possible to check whether data collection is currently enabled via
  /// the [FirebaseApp.isAutomaticDataCollectionEnabled] property.
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    return _delegate.setAutomaticDataCollectionEnabled(enabled);
  }

  /// Sets whether automatic resource management is enabled or disabled for this app.
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return _delegate.setAutomaticResourceManagementEnabled(enabled);
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FirebaseApp) {
      return false;
    }
    return other.name == name && other.options == options;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll([name, options]);

  @override
  String toString() => '$FirebaseApp($name)';
}
