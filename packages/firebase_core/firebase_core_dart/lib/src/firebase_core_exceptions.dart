// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import '../firebase_core_dart.dart';

/// Throws a consistent cross-platform error message when usage of an app occurs but
/// no app has been created.
FirebaseException noAppExists(String appName) {
  return FirebaseException(
    plugin: 'core',
    code: 'no-app',
    message:
        "No Firebase App '$appName' has been created - call Firebase.initializeApp()",
  );
}

/// Throws a consistent cross-platform error message when an app is being created
/// which already exists.
FirebaseException duplicateApp(String appName) {
  return FirebaseException(
    plugin: 'core',
    code: 'duplicate-app',
    message: 'A Firebase App named "$appName" already exists',
  );
}

/// Throws a consistent cross-platform error message if the user attempts to
/// initialize the default app from FlutterFire.
FirebaseException noDefaultAppInitialization() {
  return FirebaseException(
    plugin: 'core',
    message: 'The $defaultFirebaseAppName app cannot be initialized here. '
        'To initialize the default app, follow the installation instructions '
        'for the specific platform you are developing with.',
  );
}

/// Throws a consistent platform specific error message if the user attempts to
/// initializes core without it being available on the underlying platform.
FirebaseException coreNotInitialized() {
  String message;

  message = 'Firebase has not been initialized. '
      'Please check the documentation for initialization.';

  return FirebaseException(
    plugin: 'core',
    code: 'not-initialized',
    message: message,
  );
}

/// Throws a consistent cross-platform error message if the user attempts
/// to delete the default app.
FirebaseException noDefaultAppDelete() {
  return FirebaseException(
    plugin: 'core',
    message: 'The default Firebase app instance cannot be deleted.',
  );
}
