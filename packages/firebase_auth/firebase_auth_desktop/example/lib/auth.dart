// ignore_for_file: use_build_context_synchronously, public_member_api_docs

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/facebook.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:desktop_webview_auth/twitter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'animated_error.dart';
import 'sms_dialog.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
const redirectUri =
    'https://react-native-firebase-testing.firebaseapp.com/__/auth/handler';
const twitterApiKey = 'YEXSiWv5UeCHyy0c61O2LBC3B';
const twitterApiSecretKey =
    'DOd9dCCRFgtnqMDQT7A68YuGZtvcO4WP1mEFS4mEJAUooM4yaE';
const facebookClientId = '128693022464535';

/// Helper class to show a snackbar using the passed context.
class ScaffoldSnackbar {
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
enum AuthMode { login, register, phone }

extension on AuthMode {
  String get label => this == AuthMode.login
      ? 'Sign in'
      : this == AuthMode.phone
          ? 'Sign in'
          : 'Register';
}

/// Entrypoint example for various sign-in flows with Firebase.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String error = '';

  AuthMode mode = AuthMode.login;

  bool isLoading = false;

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  void resetError() {
    if (error.isNotEmpty) {
      setState(() {
        error = '';
      });
    }
  }

  Future _resetPassword() async {
    resetError();

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

  Future _emailAuth() async {
    resetError();

    if (formKey.currentState?.validate() ?? false) {
      setIsLoading();

      try {
        if (mode == AuthMode.login) {
          await _auth.signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
        } else if (mode == AuthMode.register) {
          await _auth.createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
        } else {
          await _onPhoneAuth();
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

  Future<void> _anonymousAuth() async {
    setIsLoading();

    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setIsLoading();
    }
  }

  Future<void> _onPhoneAuth() async {
    resetError();

    if (mode != AuthMode.phone) {
      setState(() {
        mode = AuthMode.phone;
      });
    } else {
      try {
        final confirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(phoneController.text);

        final smsCode =
            await ExampleDialog.of(context).show('SMS Code:', 'Sign in');

        if (smsCode != null) {
          await confirmationResult.confirm(smsCode);
        }
      } catch (e) {
        setState(() {
          error = '$e';
        });
      } finally {
        setIsLoading();
      }
    }
  }

  Future _onGoogleSignIn() async {
    resetError();

    try {
      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId:
              '448618578101-sg12d2qin42cpr00f8b0gehs5s7inm0v.apps.googleusercontent.com',
          redirectUri: redirectUri,
          scope: 'https://www.googleapis.com/auth/userinfo.email',
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          idToken: result.idToken,
          accessToken: result.accessToken,
        );

        // Once signed in, return the UserCredential
        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    }
  }

  Future _onTwitterSignIn() async {
    resetError();

    try {
      final result = await DesktopWebviewAuth.signIn(
        TwitterSignInArgs(
          apiKey: twitterApiKey,
          apiSecretKey: twitterApiSecretKey,
          redirectUri: redirectUri,
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = TwitterAuthProvider.credential(
          secret: result.tokenSecret!,
          accessToken: result.accessToken!,
        );

        // Once signed in, return the UserCredential
        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    }
  }

  Future _onFacebookSignIn() async {
    resetError();

    try {
      final result = await DesktopWebviewAuth.signIn(
        FacebookSignInArgs(
          clientId: facebookClientId,
          redirectUri: redirectUri,
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = FacebookAuthProvider.credential(result.accessToken!);

        // Once signed in, return the UserCredential
        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future _onAppleSignIn() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('${credential.state}');

      if (credential.identityToken != null) {
        // Create an `OAuthCredential` from the credential returned by Apple.
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: credential.identityToken,
          rawNonce: nonce,
        );

        // Sign in the user with Firebase. If the nonce we generated earlier does
        // not match the nonce in `appleCredential.identityToken`, sign in will fail.
        return await FirebaseAuth.instance
            .signInWithCredential(oauthCredential);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
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
                    const SizedBox(height: 20),
                    if (mode != AuthMode.phone)
                      Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            decoration:
                                const InputDecoration(hintText: 'Email'),
                            validator: (value) =>
                                value != null && value.isNotEmpty
                                    ? null
                                    : 'Required',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(hintText: 'Password'),
                            validator: (value) =>
                                value != null && value.isNotEmpty
                                    ? null
                                    : 'Required',
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (mode != AuthMode.phone)
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    if (mode == AuthMode.phone)
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          hintText: '+16505550101',
                          labelText: 'Phone number',
                        ),
                        validator: (value) => value != null && value.isNotEmpty
                            ? null
                            : 'Required',
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _emailAuth,
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
                        onPressed: _onGoogleSignIn,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: SignInButton(
                        Buttons.Twitter,
                        onPressed: _onTwitterSignIn,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: SignInButton(
                        Buttons.FacebookNew,
                        onPressed: _onFacebookSignIn,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (defaultTargetPlatform == TargetPlatform.macOS)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: SignInButton(
                          Buttons.Apple,
                          onPressed: _onAppleSignIn,
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (mode != AuthMode.phone) {
                                  setState(() {
                                    mode = AuthMode.phone;
                                  });
                                } else {
                                  setState(() {
                                    mode = AuthMode.login;
                                  });
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator.adaptive()
                            : Text(
                                mode != AuthMode.phone
                                    ? 'Sign in with Phone Number'
                                    : 'sign in with Email and Password',
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (mode != AuthMode.phone)
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
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyText1,
                        children: [
                          const TextSpan(text: 'Or '),
                          TextSpan(
                            text: 'continue as guest',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _anonymousAuth,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
