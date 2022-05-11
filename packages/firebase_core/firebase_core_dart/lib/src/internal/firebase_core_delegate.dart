// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of firebase_core_dart;

/// An internal delegate to perform all Firebase core functionalities.

class FirebaseCoreDelegate {
  FirebaseCoreDelegate._();

  static final _instance = FirebaseCoreDelegate._();

  final Map<String, FirebaseApp> _apps = <String, FirebaseApp>{};

  List<FirebaseApp> get apps {
    return _apps.values.toList(growable: false);
  }

  Future<FirebaseApp> initializeApp({
    String? name,
    required FirebaseOptions options,
  }) async {
    /// Ensures the name isn't null, in case no name
    /// passed, [defaultFirebaseAppName] will be used
    final _name = name ?? defaultFirebaseAppName;

    if (_apps.containsKey(_name)) {
      final existingApp = _apps[name]!;
      if (options.apiKey != existingApp.options.apiKey ||
          (options.databaseURL != null &&
              options.databaseURL != existingApp.options.databaseURL) ||
          (options.storageBucket != null &&
              options.storageBucket != existingApp.options.storageBucket)) {
        // Options are different; throw.
        throw duplicateApp(_name);
      } else {
        return existingApp;
      }
    }

    final _delegate = _FirebaseAppDelegete(this, _name, options);

    _apps[_name] = FirebaseApp._(_delegate);
    return _apps[_name]!;
  }

  FirebaseApp app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }

    throw noAppExists(name);
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FirebaseCoreDelegate) {
      return false;
    }
    return other.hashCode == hashCode;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$FirebaseCoreDelegate';
}
