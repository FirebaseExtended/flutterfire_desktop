// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:drive/drive.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';

import 'test_utils.dart';

void setupTests() {
  group('$User', () {
    group('IdToken ', () {
      test('should return a token.', () async {
        // Setup
        User? user;

        // Create a new mock user account.
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        user = userCredential.user;

        // Test
        String token = await user!.getIdToken();

        // Assertions
        expect(token.length, greaterThan(24));
      });

      test('setting forceRefresh to true generates a new token.', () async {
        // Setup
        User? user;

        // Create a new mock user account.
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        user = userCredential.user;

        // Get the current user token.
        String oldToken = await user!.getIdToken();

        // 1 second delay before sending another request.
        await Future.delayed(const Duration(seconds: 1));

        // Force refresh the token.
        String newToken =
            await FirebaseAuth.instance.currentUser!.getIdToken(true);

        expect(newToken, isNot(equals(oldToken)));
      });

      test('should catch error.', () async {
        // Setup
        User? user;

        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        user = userCredential.user!;

        // Needed for method to throw an error.
        await FirebaseAuth.instance.signOut();

        await expectLater(
          user.getIdToken(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (p0) => p0.code,
              'FirebaseAuthException with code: not-signed-in',
              'not-signed-in',
            ),
          ),
        );
      });

      test('should return a valid IdTokenResult Object.', () async {
        // Setup
        User? user;

        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        user = userCredential.user!;

        // Test
        final idTokenResult = await user.getIdTokenResult();

        // Assertions
        expect(idTokenResult.token.runtimeType, equals(String));
        expect(idTokenResult.authTime.runtimeType, equals(DateTime));
        expect(idTokenResult.issuedAtTime.runtimeType, equals(DateTime));
        expect(idTokenResult.expirationTime.runtimeType, equals(DateTime));
        expect(idTokenResult.token.length, greaterThan(24));
        expect(idTokenResult.signInProvider, equals('password'));
      });
    });
  });
}
