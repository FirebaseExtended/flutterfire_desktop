# Firebase Auth for Flutter Desktop

[![pub package](https://img.shields.io/pub/v/firebase_auth_desktop.svg)](https://pub.dev/packages/firebase_auth_desktop)

The platform implementation of FlutterFire for Linux and Windows.

> **NOTE:**
> This package overrides the existing implementation of macOS in FlutterFire for development purposes.

## Getting Started
First, please make sure you initialize Firebase for Dart by following the guide to install [`firebase_core`](https://github.com/invertase/flutterfire_desktop/tree/main/packages/firebase_core/firebase_core_desktop/README.md).

1. On the root of your project, run the following command:
    ```bash
    dart pub add firebase_auth_desktop
    ```

2. Import it:
    ```dart
    import 'package:firebase_auth_desktop/firebase_auth_desktop.dart';
    ```
## Usage

This package is a platform implementation of [`firebase_auth`](https://pub.dev/packages/firebase_auth), check the [full Usage documentation on the official guide](https://firebase.flutter.dev/docs/auth/usage).

### Phone Authentication on Desktop
On Desktop, phone authentication is similar to Web.
1. Call `signInWithPhoneNumber` method, this will trigger a reCAPTCHA webview in a seprate window for verification, once completed the user will receive SMS Code.
   ```dart
   FirebaseAuth auth = FirebaseAuth.instance;

    // Wait for the user to complete the reCAPTCHA & for an SMS code to be sent.
    ConfirmationResult confirmationResult = await auth.signInWithPhoneNumber('+44 7123 123 456');
   ```
2. Prompt the user to provide the SMS Code, then confirm it.
   ```dart
   UserCredential userCredential = await confirmationResult.confirm('123456');
   ```
However, there's currently one limitation, the SMS message that the user receives contain your App Name, on web that's usually your auth domain, but since Firebase doesn't fully
support Phone auth on desktop platforms yet, the current implementation will show your app name in the message as *127.0.0.1* which stands for the localhost IP address.
## Issue and Feedback

Please file any issues, bugs, or feature requests in [our issue tracker](https://github.com/invertase/flutterfire_desktop/issues/new/choose).

To contribute a change to this plugin, please review our [contribution guide](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md) and [open a pull request](https://github.com/invertase/flutterfire_desktop/compare).
