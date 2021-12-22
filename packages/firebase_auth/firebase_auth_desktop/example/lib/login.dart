// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:window_manager/window_manager.dart';

import 'animated_error.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Helper class to show a snackbar using the passed context.
class ScaffoldSnackbar {
  // ignore: public_member_api_docs
  ScaffoldSnackbar(this._context);

  /// The scaffold of current context.
  factory ScaffoldSnackbar.of(BuildContext context) {
    return ScaffoldSnackbar(context);
  }

  final BuildContext _context;

  /// Helper method to show a SnackBar.
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: 400,
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// The mode of the current auth session, either [AuthMode.login] or [AuthMode.register].
// ignore: public_member_api_docs
enum AuthMode { login, register }

extension on AuthMode {
  String get label => this == AuthMode.login ? 'Login' : 'Register';
}

/// Entrypoint example for various sign-in flows with Firebase.
class AuthGate extends StatefulWidget {
  // ignore: public_member_api_docs
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String error = '';

  AuthMode mode = AuthMode.login;

  bool isLoading = false;

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Future _resetPassword() async {
    String? email;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
            ),
          ],
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email'),
              const SizedBox(height: 20),
              TextFormField(
                onChanged: (value) {
                  email = value;
                },
              ),
            ],
          ),
        );
      },
    );

    if (email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email!);
        ScaffoldSnackbar.of(context).show('Password reset email is sent');
      } catch (e) {
        ScaffoldSnackbar.of(context).show('Error resetting');
      }
    }
  }

  Future onClick() async {
    if (formKey.currentState?.validate() ?? false) {
      setIsLoading();

      try {
        if (mode == AuthMode.login) {
          await _auth.signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
        } else {
          await _auth.createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
        }
      } on FirebaseAuthException catch (e) {
        setIsLoading();

        setState(() {
          error = '${e.message}';
        });
      } catch (e) {
        setIsLoading();
      }
    }
  }

  Future onGoogleSignIn() async {
    try {
      // Trigger the authentication flow
      final googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      await windowManager.show();

      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedError(text: error, show: error.isNotEmpty),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: (value) =>
                        value != null && value.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password'),
                    validator: (value) =>
                        value != null && value.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onClick,
                      child: isLoading
                          ? const CircularProgressIndicator.adaptive()
                          : Text(mode.label),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: SignInButton(
                      Theme.of(context).brightness == Brightness.dark
                          ? Buttons.Google
                          : Buttons.GoogleDark,
                      onPressed: onGoogleSignIn,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyText1,
                      children: [
                        TextSpan(
                          text: mode == AuthMode.login
                              ? "Don't have an account? "
                              : 'You have an account? ',
                        ),
                        TextSpan(
                          text: mode == AuthMode.login
                              ? 'Register now'
                              : 'Click to login',
                          style: const TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              setState(() {
                                mode = mode == AuthMode.login
                                    ? AuthMode.register
                                    : AuthMode.login;
                              });
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
