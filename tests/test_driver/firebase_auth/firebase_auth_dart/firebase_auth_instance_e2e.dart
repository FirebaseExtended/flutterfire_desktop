// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:async/async.dart';

import 'test_utils.dart';

void setupTests() {
  group('FirebaseAuth.instance', () {
    group('authStateChanges()', () {
      StreamQueue<User?>? authStateChanges;

      setUpAll(() {
        authStateChanges =
            StreamQueue(FirebaseAuth.instance.authStateChanges());
      });

      tearDown(() async {
        await authStateChanges?.cancel();
        await ensureSignedOut();
      });

      test('calls callback with the current user and when auth state changes',
          () async {
        await ensureSignedIn(testEmail);
        String uid = FirebaseAuth.instance.currentUser!.uid;

        expect(
          (await authStateChanges?.next)?.uid,
          equals(uid),
        );

        await FirebaseAuth.instance.signOut();

        expect(
          (await authStateChanges?.next),
          isNull,
        );

        await FirebaseAuth.instance.signInAnonymously();

        expect(
          (await authStateChanges?.next)?.uid != uid,
          isTrue,
        );
      });
    });

    group('idTokenChanges()', () {
      StreamQueue<User?>? idTokenChanges;

      setUpAll(() {
        idTokenChanges = StreamQueue(FirebaseAuth.instance.idTokenChanges());
      });

      tearDown(() async {
        await idTokenChanges?.cancel();
        await ensureSignedOut();
      });

      test('calls callback with the current user and when idToken changes',
          () async {
        await ensureSignedIn(testEmail);
        String uid = FirebaseAuth.instance.currentUser!.uid;

        expect(
          (await idTokenChanges?.next)?.uid,
          equals(uid),
        );

        await FirebaseAuth.instance.signOut();

        expect(
          (await idTokenChanges?.next),
          isNull,
        );

        await FirebaseAuth.instance.signInAnonymously();

        expect(
          (await idTokenChanges?.next)?.uid != uid,
          isTrue,
        );
      });
    });

    group('signInWithEmailAndPassword() ', () {
      test('sign-in updates currentUser and events.', () async {
        // Tests
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        expect(credential, isA<UserCredential>());
        expect(credential.user!.email, equals(testEmail));
      });

      test('should throw.', () async {
        expect(
          () => FirebaseAuth.instance
              .signInWithEmailAndPassword('test+1@gmail.com', testPassword),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'error code',
              'email-not-found',
            ),
          ),
        );
      });

      test('sign-out.', () async {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(testEmail, testPassword);

        await FirebaseAuth.instance.signOut();

        expect(FirebaseAuth.instance.currentUser, isNull);
      });
    });

    group('signInWithCustomToken()', () {
      test('signs in with custom token', () async {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        final uid = userCredential.user!.uid;
        final claims = {
          'roles': [
            {'role': 'member'},
            {'role': 'admin'}
          ]
        };

        await ensureSignedOut();

        expect(FirebaseAuth.instance.currentUser, null);

        final token = emulatorCreateCustomToken(uid, claims: claims);

        final cred = await FirebaseAuth.instance.signInWithCustomToken(token);

        expect(FirebaseAuth.instance.currentUser, equals(cred.user));
        final user = cred.user!;
        expect(user.isAnonymous, isFalse);
        expect(user.uid, equals(uid));

        final idTokenResult =
            await FirebaseAuth.instance.currentUser!.getIdTokenResult();

        expect(idTokenResult.claims!['roles'], isA<List>());
        expect(idTokenResult.claims!['roles'][0], isA<Map>());
        expect(idTokenResult.claims!['roles'][0]['role'], 'member');
      });
    });
  });
}
