// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/facebook.dart';
import 'package:desktop_webview_auth/github.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:desktop_webview_auth/twitter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth.dart';

const _redirectUri =
    'https://react-native-firebase-testing.firebaseapp.com/__/auth/handler';
const _googleClientId =
    '448618578101-sg12d2qin42cpr00f8b0gehs5s7inm0v.apps.googleusercontent.com';
const _twitterApiKey = 'YEXSiWv5UeCHyy0c61O2LBC3B';
const _twitterApiSecretKey =
    'DOd9dCCRFgtnqMDQT7A68YuGZtvcO4WP1mEFS4mEJAUooM4yaE';
const _facebookClientId = '128693022464535';
const _githubClientId = '582d07c80a9afae77406';
const _githubClientSecret = '2d60f5e850bc178dfa6b7f6c6e37a65b175172d3';

/// Provide authentication services with [FirebaseAuth].
class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<void> emailAuth(
    AuthMode mode, {
    required String email,
    required String password,
  }) {
    assert(mode != AuthMode.phone);

    try {
      if (mode == AuthMode.login) {
        return _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        return _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> anonymousAuth() {
    try {
      return _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> phoneAuth({
    required String phoneNumber,
    required Future<String?> Function() smsCode,
  }) async {
    try {
      final confirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);

      final _smsCode = await smsCode.call();

      if (_smsCode != null) {
        await confirmationResult.confirm(_smsCode);
      } else {
        return;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> googleSignIn() async {
    try {
      // Handle login by a third-party provider.
      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId:
              '448618578101-sg12d2qin42cpr00f8b0gehs5s7inm0v.apps.googleusercontent.com',
          redirectUri: _redirectUri,
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
      } else {
        return;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  Future<void> twitterSignIn() async {
    try {
      // Handle login by a third-party provider.
      final result = await DesktopWebviewAuth.signIn(
        TwitterSignInArgs(
          apiKey: _twitterApiKey,
          apiSecretKey: _twitterApiSecretKey,
          redirectUri: _redirectUri,
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
      } else {
        return;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  Future<void> facebookSignIn() async {
    try {
      // Handle login by a third-party provider.
      final result = await DesktopWebviewAuth.signIn(
        FacebookSignInArgs(
          clientId: _facebookClientId,
          redirectUri: _redirectUri,
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = FacebookAuthProvider.credential(result.accessToken!);

        // Once signed in, return the UserCredential
        await _auth.signInWithCredential(credential);
      } else {
        return;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  Future<void> githubSignIn() async {
    try {
      // Handle login by a third-party provider.
      final result = await DesktopWebviewAuth.signIn(
        GitHubSignInArgs(
          clientId: _githubClientId,
          clientSecret: _githubClientSecret,
          redirectUri: _redirectUri,
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = GithubAuthProvider.credential(result.accessToken!);

        // Once signed in, return the UserCredential
        await _auth.signInWithCredential(credential);
      } else {
        return;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future appleSignIn() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

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
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      } else {
        return;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) {
    try {
      return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> linkWithGoogle() async {
    try {
      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId: _googleClientId,
          redirectUri: _redirectUri,
          scope: 'https://www.googleapis.com/auth/userinfo.email',
        ),
      );

      if (result != null) {
        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: result.accessToken,
          idToken: result.idToken,
        );

        // Once signed in, return the UserCredential
        await _auth.currentUser?.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  /// Sign the Firebase user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
