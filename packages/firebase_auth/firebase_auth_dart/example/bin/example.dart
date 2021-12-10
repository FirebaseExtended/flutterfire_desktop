// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';

FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
      authDomain: 'https://react-native-firebase-testing.firebaseapp.com',
    );

final bluePen = AnsiPen()..blue(bold: true);
final redPen = AnsiPen()..red(bold: true);
final greenPen = AnsiPen()..green(bold: true);

/// Simple CLI app that uses Firebase Auth to login.
Future main(List<String> args) async {
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseAuth.instance.useAuthEmulator();

  final verbose = args.contains('-v');
  final logger = verbose ? Logger.verbose() : Logger.standard();

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    await loginRegister(logger);
  } else {
    stdout.writeln(greenPen('Welcome back ${currentUser.email}! 👋'));
    stdout.write('Logout? (Y/n): ');
    final bool logout;

    if (stdin.readLineSync() == 'Y') {
      logout = true;
    } else {
      logout = false;
    }

    if (logout) {
      final progress = logger.progress('Logging out');
      await FirebaseAuth.instance.signOut();
      progress.finish(message: 'Bye-bye~');
    }

    exitCode = 0;
  }
}

Future loginRegister(Logger logger) async {
  stdout.writeln(bluePen('Please login/register to continue'));

  stdout.write('Email: ');
  final email = stdin.readLineSync();

  stdout.write('Password: ');

  stdin.echoMode = false;
  stdin.lineMode = false;

  final password = stdin.readLineSync();
  stdout.writeln();

  stdin.echoMode = true;
  stdin.lineMode = true;

  if (email != null && password != null) {
    final loginProgress = logger.progress('Attempting to sign in');

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email, password);
      loginProgress.finish();

      stdout.writeln(greenPen('Signed in successfully! 🎉'));

      exit(0);
    } catch (e) {
      loginProgress.finish();

      if (e is FirebaseAuthException && e.code == 'EMAIL_NOT_FOUND') {
        final registerProgress = logger.progress(
          'No account found, attempting to register a new one',
        );
        try {
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email, password);

          registerProgress.finish();
          stderr.writeln(greenPen('Signed in successfully! 🎉'));
          exit(0);
        } catch (e) {
          registerProgress.finish();

          stderr.writeln(redPen(e));

          exit(2);
        }
      } else {
        stderr.writeln(redPen(e));
        exit(2);
      }
    }
  }
}
