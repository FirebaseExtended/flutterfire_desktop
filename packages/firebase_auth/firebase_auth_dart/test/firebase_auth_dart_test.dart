// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_dynamic_calls
import 'dart:async';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'firebase_auth_dart_test.mocks.dart';

@GenerateMocks([User, FirebaseAuth, UserCredential])
void main() {
  late FirebaseAuth fakeAuth;
  final user = MockUser();
  final userCred = MockUserCredential();

  group('$FirebaseAuth', () {
    setUpAll(() async {
      const options = FirebaseOptions(
        apiKey: 'api-key',
        authDomain: '...',
        databaseURL: '...',
        projectId: '...',
        storageBucket: '...',
        messagingSenderId: '...',
        appId: '...',
      );

      await Firebase.initializeApp(options: options);
    });
    setUp(() async {
      fakeAuth = MockFirebaseAuth();

      when(fakeAuth.authStateChanges())
          .thenAnswer((_) => Stream.fromIterable([user]));
      when(fakeAuth.idTokenChanges())
          .thenAnswer((_) => Stream.fromIterable([user]));
      when(fakeAuth.signInAnonymously())
          .thenAnswer((_) => Future<UserCredential>.value(userCred));
      when(userCred.user).thenReturn(user);
      when(fakeAuth.currentUser).thenReturn(user);
    });
    group('signInWithCredential()', () {
      test('Google', () {});
      test('Twitter', () {});
      test('Facebook', () {});
    });
    group('unlink()', () {
      test('should unlink phone number', () async {});
    });
    group('Set languageCode ', () {
      setUp(() {
        when(fakeAuth.languageCode).thenReturn('ar');
      });
      test('updates the instance laguage code.', () async {
        fakeAuth.setLanguageCode('ar');
        expect(
          fakeAuth.languageCode,
          equals('ar'),
        );
      });
    });

    group('IdToken ', () {
      test('user have IdToken and refreshToken.', () async {
        when(user.refreshToken).thenReturn('refreshToken');
        when(user.getIdToken()).thenAnswer((_) async => 'token');

        expect(await fakeAuth.currentUser!.getIdToken(), isA<String>());
        expect(fakeAuth.currentUser!.refreshToken, isA<String>());

        verify(user.getIdToken());
        verify(user.refreshToken);
      });
      test('force refresh.', () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');
        when(user.getIdToken(true)).thenAnswer((_) async => 'token_refreshed');

        final userCred = await fakeAuth.signInAnonymously();
        final oldToken = await userCred.user!.getIdToken();
        final token = await fakeAuth.currentUser!.getIdToken(true);

        expect(token, isNot(equals(oldToken)));
      });
      test("getIdToken doesn't force refresh.", () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');

        await fakeAuth.signInAnonymously();
        final token = await fakeAuth.currentUser!.getIdToken();

        expect(token, equals(await fakeAuth.currentUser!.getIdToken()));
      });
      test('event recieved once force refreshed.', () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');
        when(user.getIdToken(true)).thenAnswer((_) async => 'token_refreshed');

        final userCred = await fakeAuth.signInAnonymously();
        final oldToken = await userCred.user!.getIdToken();

        expect(
          await (await fakeAuth.idTokenChanges().last)!.getIdToken(true),
          isNot(equals(oldToken)),
        );
      });
    });
    group('Password ', () {
      const mockEmail = 'test@test.com';
      const mockPassword = 'password';
      const mockOobCode = 'code';
      test('confirmPasswordReset() completes.', () async {
        // Mocking, not e2e since the real endpoint would throw on invalid Oob
        when(fakeAuth.confirmPasswordReset(any, any))
            .thenAnswer((_) async => mockEmail);
        await expectLater(
          fakeAuth.confirmPasswordReset(mockOobCode, mockPassword),
          completion(mockEmail),
        );
        verify(fakeAuth.confirmPasswordReset(mockOobCode, mockPassword));
      });
      test('verifyPasswordResetCode() throws.', () async {
        // Mocking, not e2e since the real endpoint would throw on invalid Oob
        when(fakeAuth.verifyPasswordResetCode(any))
            .thenAnswer((_) async => mockEmail);
        await expectLater(
          fakeAuth.verifyPasswordResetCode(mockOobCode),
          completion(mockEmail),
        );
        verify(fakeAuth.verifyPasswordResetCode(mockOobCode));
      });
    });
    group('User ', () {
      test('sendEmailVerification()', () async {
        when(fakeAuth.currentUser).thenReturn(user);
        when(user.sendEmailVerification()).thenAnswer((_) async {});

        await fakeAuth.signInAnonymously();
        await fakeAuth.currentUser!.sendEmailVerification();

        verify(user.sendEmailVerification());
      });

      group('linkWithCredential()', () {
        setUp(() {
          when(user.linkWithCredential(any)).thenAnswer((_) async => userCred);
        });
        test('should call linkWithCredential()', () async {
          const newEmail = 'new@email.com';

          final credential =
              EmailAuthProvider.credential(email: newEmail, password: 'test')
                  as EmailAuthCredential;

          await fakeAuth.currentUser!.linkWithCredential(credential);

          verify(user.linkWithCredential(credential));
        });
      });
      group('reauthenticateWithCredential()', () {
        setUp(() {
          when(user.reauthenticateWithCredential(any))
              .thenAnswer((_) async => userCred);
        });
        test('should call reauthenticateWithCredential()', () async {
          const newEmail = 'new@email.com';

          final credential =
              EmailAuthProvider.credential(email: newEmail, password: 'test')
                  as EmailAuthCredential;

          await fakeAuth.currentUser!.reauthenticateWithCredential(credential);

          verify(user.reauthenticateWithCredential(credential));
        });
      });
    });
    // group('StorageBox ', () {
    //   test('put a new value.', () {
    //     final box = StorageBox.instanceOf('box');
    //     box.putValue('key', '123');

    //     expect(box.getValue('key'), '123');
    //   });
    //   test('put a null value does not add the value.', () {
    //     final box = StorageBox.instanceOf('box');
    //     box.putValue('key_2', null);
    //     expect(
    //       () => box.getValue('key_2'),
    //       throwsA(isA<StorageBoxException>()),
    //     );
    //   });
    //   test('get a key that does not exist.', () {
    //     final box = StorageBox.instanceOf('box');
    //     expect(
    //       () => box.getValue('random_key'),
    //       throwsA(isA<StorageBoxException>()),
    //     );
    //   });
    //   test('get a key from a box that does not exist.', () {
    //     final box = StorageBox.instanceOf('box_');
    //     expect(
    //       () => box.getValue('key'),
    //       throwsA(isA<StorageBoxException>()),
    //     );
    //   });
    // });
  });
}
