// ignore_for_file: depend_on_referenced_packages, public_member_api_docs

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_builder.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:window_manager/window_manager.dart';

import 'register_page.dart';
import 'signin_page.dart';

/// Initialize with a secondary app until dart-only initialization is merged.
FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
      authDomain: 'https://react-native-firebase-testing.firebaseapp.com',
    );

// Requires that the Firebase Auth emulator is running locally
// e.g via `melos run firebase:emulator`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  await GoogleSignInDart.register(
    clientId:
        '448618578101-sg12d2qin42cpr00f8b0gehs5s7inm0v.apps.googleusercontent.com',
  );
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  runApp(AuthExampleApp());
}

/// The entry point of the application.
///
/// Returns a [MaterialApp].
class AuthExampleApp extends StatelessWidget {
  AuthExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Example App',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: AuthTypeSelector(),
      ),
    );
  }
}

/// Provides a UI to select a authentication type page
class AuthTypeSelector extends StatelessWidget {
  AuthTypeSelector({Key? key}) : super(key: key);

  // Navigates to a new page
  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context) /*!*/ .push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Example App'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: SignInButtonBuilder(
              icon: Icons.person_add,
              backgroundColor: Colors.indigo,
              text: 'Registration',
              onPressed: () => _pushPage(context, RegisterPage()),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: SignInButtonBuilder(
              icon: Icons.verified_user,
              backgroundColor: Colors.orange,
              text: 'Sign In',
              onPressed: () => _pushPage(context, SignInPage()),
            ),
          ),
        ],
      ),
    );
  }
}
