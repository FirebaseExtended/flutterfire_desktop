# Firebase Core for Dart

[![pub package](https://img.shields.io/pub/v/firebase_core_dart.svg)](https://pub.dev/packages/firebase_core_dart)

A pure Dart implementation for Firebase Core, which helps you initialize multiple Firebase Apps for your Dart project.
This package is used by the [Firebase Core Desktop](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_desktop) plugin.
## Getting Started

This package can be used with **pure Dart apps**, so if you are aiming to use Firebase for your Flutter app, please use [`firebase_core`](https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_core/firebase_core) for iOS, Android, macOS and Web, and add [`firebase_core_desktop`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_desktop) for Linux and Windows.

1. On the root of your project, run the following command:
    ```bash
    dart pub add firebase_core_dart
    ```

2. Import it:
    ```dart
    import 'package:firebase_core_dart/firebase_core_dart.dart';
    ```
## Usage

To initialize the default app, add your configurations as options to `initializeApp` method without a name.
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

Note that initialization should happen before any other usage of Firebase Dart packages.

### Initialize Secondary Apps

To initialize a secondary app, provide the name to `initializeApp` method:
```dart
await Firebase.initializeApp(app: 'foo', options: firebaseOptions);
```

## Issue and Feedback

Please file any issues, bugs, or feature requests in [our issue tracker](https://github.com/invertase/flutterfire_desktop/issues/new/choose).

To contribute a change to this plugin, please review our [contribution guide](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md) and [open a pull request](https://github.com/invertase/flutterfire_desktop/compare).
