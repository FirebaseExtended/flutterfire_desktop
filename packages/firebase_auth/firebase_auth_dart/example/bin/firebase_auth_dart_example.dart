// ignore_for_file: public_member_api_docs, require_trailing_commas

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
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

Logger logger = Logger.standard();

/// Simple CLI app that uses Firebase Auth to login.
Future main(List<String> args) async {
  final parser = ArgParser();

  parser.addCommand('login');
  parser.addCommand('logout');
  parser.addCommand('info');
  parser.addCommand('update-password');

  parser.commands['login']!.addCommand('reset-password').addOption('email');

  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseAuth.instance.useAuthEmulator();

  final verbose = args.contains('-v');
  if (verbose) {
    logger = Logger.verbose();
  }

  final currentUser = FirebaseAuth.instance.currentUser;

  final parsedArgs = parser.parse(args);

  final mainCommand = AppCommand.fromArgs(parsedArgs.command);

  AppCommand? secondaryCommand;
  if (parsedArgs.command != null) {
    secondaryCommand = AppCommand.fromArgs(parsedArgs.command?.command);
  }

  switch (mainCommand.name) {
    case 'login':
      switch (secondaryCommand?.name) {
        case 'reset-password':
          // login reset-password --email email@test.com
          await resetPassword(
              currentUser, secondaryCommand?.arguments?['email']);
          break;
        default:
          if (currentUser == null) {
            await authenticate();
          } else {
            await printInfo(currentUser);
            exitCode = 0;
          }
      }
      break;
    case 'logout':
      await logout(currentUser);
      break;
    case 'update-password':
      await resetPassword(currentUser, secondaryCommand?.arguments?['email']);
      break;
    default:
  }
}

Future<void> resetPassword(User? currentUser, String? email) async {
  var _email = email;

  if (currentUser == null) {
    stdout.write('Forgot your password? (Y/n): ');

    final bool answer;

    if (stdin.readLineSync() == 'Y') {
      answer = true;
    } else {
      answer = false;
    }

    if (answer) {
      if (_email == null) {
        stdout.write('What is your email? ');
        _email ??= stdin.readLineSync();
      }

      final progress = logger.progress('Resetting your password');

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _email ?? '');
        progress.finish();

        stdout.writeln(greenPen(
            'Password reset email was sent to $_email, check your inbox.'));
        exitCode = 0;
      } catch (e) {
        progress.finish();

        stderr.writeln(redPen(e));
        exitCode = 2;
      }
    } else {
      exit(0);
    }
  } else {
    stdin.echoMode = false;
    stdin.lineMode = false;

    stdout.write('Current password: ');
    final password = stdin.readLineSync();

    if (password != null) {
      stdout.writeln();

      try {
        await currentUser.reauthenticateWithCredential(
            EmailAuthProvider.credential(
                email: currentUser.email!, password: password));

        stdout.write('New password: ');
        final newPassword = stdin.readLineSync();

        final progress = logger.progress('Resetting your password');

        if (newPassword != null) {
          await currentUser.updatePassword(newPassword);

          progress.finish();

          stdout.writeln(greenPen('Password updated successfully.'));
        }
      } catch (e) {
        stderr.writeln(redPen(e));
        exitCode = 2;
      }
    }

    stdin.echoMode = true;
    stdin.lineMode = true;
    exit(0);
  }
}

Future<void> printInfo(User user) async {
  stdout.writeln(greenPen(
      'You are currently logged in as ${user.email ?? user.phoneNumber}! 👋'));
}

Future<void> logout(User? user) async {
  if (user == null) {
    stdout.writeln(greenPen("There's no current user, login to continue"));
    return;
  }
  stdout
      .writeln(greenPen('Welcome back ${user.email ?? user.phoneNumber}! 👋'));
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
}

Future<void> authenticate() async {
  stdout.writeln(bluePen('Please login/register to continue'));

  stdout.write('Email/Phone: ');
  final input = stdin.readLineSync();

  if (input?.contains('@') ?? false) {
    final email = input!;
    final password = await getPassword();

    if (password != null) {
      await emailAndPasswordAuth(email, password);
    }
  } else {
    final phone = input!;
    await phoneAuth(phone);
  }
}

Future<void> phoneAuth(String phone) async {
  final loginProgress =
      logger.progress('Attempting to sign in with phone number $phone');

  try {
    final confirmationResult =
        await FirebaseAuth.instance.signInWithPhoneNumber(phone);

    stdout.write('\nSMS Code: ');
    final smscode = stdin.readLineSync();

    await confirmationResult.confirm(smscode ?? '');

    loginProgress.finish();
    stdout.writeln(greenPen('Signed in successfully! 🎉'));
    exit(0);
  } catch (e, s) {
    log('$s');
    loginProgress.finish();
    stderr.writeln(redPen(e));
    exit(2);
  }
}

Future<void> emailAndPasswordAuth(String email, String password) async {
  final loginProgress =
      logger.progress('Attempting to sign in with email $email');

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email, password);
    loginProgress.finish();

    stdout.writeln(greenPen('Signed in successfully! 🎉'));

    exit(0);
  } catch (e) {
    loginProgress.finish();

    if (e is FirebaseAuthException && e.code == 'email-not-found') {
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

Future<String?> getPassword() async {
  stdout.write('Password: ');

  stdin.echoMode = false;
  stdin.lineMode = false;

  final password = stdin.readLineSync();
  stdout.writeln();

  stdin.echoMode = true;
  stdin.lineMode = true;

  return password;
}

class AppCommand {
  AppCommand({this.name, this.arguments});

  factory AppCommand.fromArgs(ArgResults? arg) {
    return AppCommand(
      name: arg?.name,
      arguments: arg,
    );
  }

  final String? name;
  final ArgResults? arguments;
}
