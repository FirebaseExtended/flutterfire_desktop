# Firebase Core for Flutter Desktop

[![pub package](https://img.shields.io/pub/v/firebase_core_desktop.svg)](https://pub.dev/packages/firebase_core_desktop)

A Flutter plugin to use the Firebase Core API on Linux and Windows, which enables connecting to multiple Firebase apps.

To learn more about Firebase, please visit the [Firebase website](https://firebase.google.com/).

## Getting Started

Follow these steps to install Firebase Core for your Desktop app.
1. On the root of your project, run the following commands:
    ```bash
    flutter pub add firebase_core
    flutter pub add firebase_core_desktop
    ```
    **Note:** `firebase_core_desktop` is a platform implementation of the main `firebase_core` plugin, so you must install them both, if you don't already have `firebase_core`.

2. Import it:
    ```dart
    import 'package:firebase_core/firebase_core.dart';
    ```

## Usage

### Initialize Default App

Unlike firebase_core for iOS, Android, macOS and Web, there's no need for platform specific config files to initialize the default Firebase App, 
instead, add your configurations as options to `initializeApp` method without a name.
```dart
const firebaseOptions = FirebaseOptions(
  appId: '...',
  apiKey: '...',
  projectId: '...',
  messagingSenderId: '...',
  authDomain: '...',
);

await Firebase.initializeApp(options: firebaseOptions);
```

You migh want to pass your configuration as environment variables if you're pushing to a public repository:
```dart
const firebaseOptions = FirebaseOptions(
  appId: const String.fromEnvironment('FIREBASE_APP_ID'),
  apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
  projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
  messagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID'),
  authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
);
```

Note that initialization should happen before any other usage of FlutterFire plugins.

### Initialize Secondary Apps

To initialize a secondary app, provide the name to `initializeApp` method:
```dart
await Firebase.initializeApp(app: 'foo', options: firebaseOptions);
```

Check the [full usage example](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_desktop/example).

## Issue and Feedback

Please file FlutterFire specific issues, bugs, or feature requests in [our issue tracker](https://github.com/invertase/flutterfire_desktop/issues/new/choose).

Plugin issues that are not specific to the desktop plugin can be filed in the main FlutterFire [issue tracker](https://github.com/FirebaseExtended/flutterfire/issues/new).

To contribute a change to this plugin, please review our [contribution guide](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md) and [open a pull request](https://github.com/invertase/flutterfire_desktop/compare).
