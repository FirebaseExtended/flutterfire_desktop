# Firebase Auth for Dart

[![pub package](https://img.shields.io/pub/v/firebase_auth_dart.svg)](https://pub.dev/packages/firebase_auth_dart)

A pure Dart implementation for Firebase Auth, which helps you authenticate users using multiple methods and providers.
This package is used by the [Firebase Auth Desktop](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_auth/firebase_auth_desktop) plugin.
## Getting Started

This package can be used with **pure Dart apps**, so if you are aiming to use Firebase for your Flutter app, please use [`firebase_auth`](https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_auth/firebase_auth) for iOS, Android, macOS and Web, and add [`firebase_auth_desktop`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_auth/firebase_auth_desktop) for Linux and Windows.

First, please make sure you initialize Firebase for Dart by following the guide to [install `firebase_core`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_dart/README.md).

1. On the root of your project, run the following command:
    ```bash
    dart pub add firebase_auth_dart
    ```

2. Import it:
    ```dart
    import 'package:firebase_auth_dart/firebase_auth_dart.dart';
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

1. `authStateChanges()`: fires event upon changes in `User` state, on sign in and sign out.
```dart
 FirebaseAuth.instance
  .authStateChanges()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
```
2. `idTokenChanges()`: in addition to listening to the changes in `User` state, it also fires events when the current user's token changes.
```dart
   FirebaseAuth.instance
  .idTokenChanges()
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

The user will persist across sessions, such as restarting the app, until the user explicitly signs out, or delete the app and its cache.

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
   
#### OAuth providers

The package supports OAuth sign-in providers such as Google, through `signInWithCredential()` method.
This method takes a `AuthCredential` object, which requires the providerId and signInMethod.

However, to authenticate via an OAuth provider, you will need some kind of token returned after the user
signs in with the provider to be passed to `signInWithCredential()`, mostly it means using another package to carry this flow for you. Currently, there's no package for any provider that is Dart only and not dependent on the Flutter SDK.

#### Phone Auth

To authenticate users using phone number, you need to enable Phone as a sign-in provider in Firebase Console for your project.
Once enabled, trigger the auth flow by calling `signInWithPhoneNumber` method. 
```dart
// Wait for the user to complete the reCAPTCHA & for an SMS code to be sent.
ConfirmationResult confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber('+44 7123 123 456');
```
This method will open the default browser of the user
for reCAPTCHA verification. Once complete, you can then sign the user in by providing the SMS code to the confirm method on the resolved 
`ConfirmationResult` response:
```dart
UserCredential userCredential = await confirmationResult.confirm('123456');
```
### Signing Out

To sign a user out, call the `signOut()` method:
```dart
await FirebaseAuth.instance.signOut();
```
If you are listening to changes in authentication state, a new event will be sent to your listeners.
### User management
Once authenticated, you have access to the user via the User class. The class stores the current information about the user such as their unique user ID, any linked provider accounts and methods to manage the user.

The User class is returned from any authentication state listeners, or as part of a UserCredential when using authentication methods. If you are sure the user is currently signed-in, you can also access the User via the `currentUser` property on the `FirebaseAuth` instance. The examples below show how to access the user:

1. Via `currentUser`:

    ```dart
    var currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      print(currentUser.uid);
    }
    ```
2. Via Sign-in methods:

    ```dart
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();

    print(userCredential.user!.uid);
    ```
3. Via state listener stream:

    ```dart
    FirebaseAuth.instance
      .authStateChanges()
      .listen((User? user) {
        if (user != null) {
          print(user.uid);
        }
      });
    ```

#### Deleting a user
If your user wishes to delete their account from your project, this can be achieved with the `delete()` method. Since this is a security-sensitive operation, it requires that user must have recently signed-in. You can handle this scenario by catching the error, for example:
```dart
try {
  await FirebaseAuth.instance.currentUser!.delete();
} on FirebaseAuthException catch (e) {
  if (e.code == 'requires-recent-login') {
    print('The user must reauthenticate before this operation can be executed.');
  }
}
```
#### Reauthenticating a user
As mentioned above, some operations such as deleting the user, updating their email address or providers require the user to have recently signed in. Rather than signing the user out and back in again, the `reauthenticateWithCredential()` method can be called. If a recent login is required, create a new AuthCredential and pass it to the method. For example, to reauthenticate with email & password, create a new `EmailAuthCredential`:
```dart
// Prompt the user to enter their email and password
String email = 'barry.allen@example.com';
String password = 'SuperSecretPassword!';

// Create a credential
AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);

// Reauthenticate
await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
```
#### Emulator Usage
If you are using the local Authentication emulator, then it is possible to connect to this using the useAuthEmulator method. Ensure you pass the correct port on which the Firebase emulator is running on. Ensure you have enabled network connections to the emulators in your apps following the emulator usage instructions in the general FlutterFire installation notes for each operating system.
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Ideal time to initialize
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  //...
}
```
## Issue and Feedback

Please file any issues, bugs, or feature requests in [our issue tracker](https://github.com/invertase/flutterfire_desktop/issues/new/choose).

To contribute a change to this plugin, please review our [contribution guide](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md) and [open a pull request](https://github.com/invertase/flutterfire_desktop/compare).
