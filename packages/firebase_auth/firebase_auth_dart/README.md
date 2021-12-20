# Firebase Auth for Dart

[![pub package](https://img.shields.io/pub/v/firebase_auth_dart.svg)](https://pub.dev/packages/firebase_auth_dart)

A pure Dart implementation for Firebase Auth, which helps you authenticate users using multiple methods and providers.
This package is used by the [Firebase Auth Desktop](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_auth/firebase_auth_dart) plugin.
## Getting Started

This package can be used with **pure Dart apps**, so if you are aiming to use Firebase for your Flutter app, please use [`firebase_auth`](https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_auth/firebase_auth) for iOS, Android, macOS and Web, and add [`firebase_auth_desktop`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_auth/firebase_auth_desktop) for Linux and Windows.

First, please make sure you initialize Firebase for Dart by following the guide to [install `firebase_core`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_dart/README.md).

1. On the root of your project, run the following command:
    ```bash
    dart pub add firebase_auth_dart
    ```

2. Import it:
    ```dart
    import 'package:firebase_core_dart/firebase_auth_dart.dart';
    ```
## Usage

Initialize the package by calling the API entry point:

```dart
FirebaseAuth auth = FirebaseAuth.instance;
```

By default, this allows you to interact with Firebase Auth using the default Firebase App used whilst installing Firebase. If however you'd like to use a secondary Firebase App, use the `instanceFor` method:

```dart
FirebaseApp secondaryApp = Firebase.app('SecondaryApp');
FirebaseAuth auth = FirebaseAuth.instanceFor(app: secondaryApp);
```

### Authentication state

You can listen to changes in authentication states through the following streams:

1. `onAuthStateChanged()`: fires event upon changes in `User` state, on sign in and sign out.
   ```dart
   FirebaseAuth.instance
  .onAuthStateChanged()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
   ```
2. `onIdTokenChanged()`: in addition to listening to the changes in `User` state, it also fires events when the current user's token changes.
   ```dart
   FirebaseAuth.instance
  .onIdTokenChanged()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
   ```

### Sign-in methods

#### Anonymous sign-in

To sign-in a user anonymously, call the `signInAnonymously()` method on the FirebaseAuth instance:

```dart
UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
```

The user will persist accross sessions, such as restarting the app, until the user explicitly signs out, or delete the app and its cahces.

#### Email/Password Registration & Sign-in

1. Registration:
   ```dart
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "barry.allen@example.com",
        password: "SuperSecretPassword!"
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
   ```
2. Sign-in:
   ```dart
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "barry.allen@example.com",
        password: "SuperSecretPassword!"
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
   ```

## Issue and Feedback

Please file any issues, bugs, or feature requests in [our issue tracker](https://github.com/invertase/flutterfire_desktop/issues/new/choose).

To contribute a change to this plugin, please review our [contribution guide](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md) and [open a pull request](https://github.com/invertase/flutterfire_desktop/compare).
