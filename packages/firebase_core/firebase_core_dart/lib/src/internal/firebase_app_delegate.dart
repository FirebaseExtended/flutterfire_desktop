// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of firebase_core_dart;

/// The default Firebase application name.
const String defaultFirebaseAppName = '[DEFAULT]';

/// An internal delegate class storing the name and options of a Firebase app.
class _FirebaseAppDelegete {
  // ignore: public_member_api_docs
  _FirebaseAppDelegete(this._firebase, this.name, this.options);

  final FirebaseCoreDelegate _firebase;

  /// The name of this Firebase app.
  final String name;

  /// Returns the [FirebaseOptions] that this app was configured with.
  final FirebaseOptions options;

  /// Returns whether automatic data collection enabled or disabled.
  bool _isAutomaticDataCollectionEnabled = false;

  /// Returns whether this instance is the default Firebase app.
  // bool get _isDefault => name == defaultFirebaseAppName;

  /// Returns true if automatic data collection is enabled for this app.
  bool get isAutomaticDataCollectionEnabled =>
      _isAutomaticDataCollectionEnabled;

  /// Deletes the current FirebaseApp.
  void delete() {
    _firebase._apps.remove(name);
  }

  /// Sets whether automatic data collection is enabled or disabled for this app.
  /// This has no affect on Desktop.
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    _isAutomaticDataCollectionEnabled = enabled;
    return Future.value();
  }

  /// Sets whether automatic resource management is enabled or disabled for this app.
  /// This has no affect on Desktop.
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {
    return Future.value();
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! _FirebaseAppDelegete) {
      return false;
    }
    return other.name == name && other.options == options;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(name, options);

  @override
  String toString() => '$_FirebaseAppDelegete($name)';
}
