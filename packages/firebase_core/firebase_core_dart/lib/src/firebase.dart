// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of firebase_core_dart;

/// Entry point of Firebase Core for dart-only apps.
class Firebase {
  // Ensures end-users cannot initialize the class.
  Firebase._();

  // Cached & lazily loaded instance of [FirebasePlatform].
  // Avoids a [MethodChannelFirebase] being initialized until the user
  // starts using Firebase.
  // The property is visible for testing to allow tests to set a mock
  // instance directly as a static property since the class is not initialized.
  @visibleForTesting
  // ignore: public_member_api_docs
  static FirebaseCoreDelegate? delegatePackingProperty;

  static FirebaseCoreDelegate get _delegate =>
      delegatePackingProperty ?? FirebaseCoreDelegate._instance;

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of
  /// the Dart only `*_dart` plugins.
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
