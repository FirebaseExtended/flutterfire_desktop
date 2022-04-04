// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:async/async.dart';

import 'test_utils.dart';

void setupTests() {
  group('FirebaseAuth.instance', () {
    Future<void> commonSuccessCallback(currentUserCredential) async {
      var currentUser = currentUserCredential.user;

      expect(currentUser, isInstanceOf<Object>());
      expect(currentUser.uid, isInstanceOf<String>());
      expect(currentUser.email, equals(testEmail));
      expect(currentUser.isAnonymous, isFalse);
      expect(currentUser.uid, equals(FirebaseAuth.instance.currentUser!.uid));

      var additionalUserInfo = currentUserCredential.additionalUserInfo;
      expect(additionalUserInfo, isInstanceOf<Object>());
      expect(additionalUserInfo.isNewUser, isFalse);

      await FirebaseAuth.instance.signOut();
    }

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

    group('currentUser', () {
      test('should return currentUser', () async {
        await ensureSignedIn(testEmail);
        var currentUser = FirebaseAuth.instance.currentUser;
        expect(currentUser, isA<User>());
      });
    });

    group('confirmPasswordReset()', () {
      test('throws on invalid code', () async {
        try {
          await FirebaseAuth.instance
              .confirmPasswordReset('!!!!!!', 'thingamajig');
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('invalid-action-code'));
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('should create a user with an email and password', () async {
        var email = generateRandomEmail();

        Function successCallback = (UserCredential newUserCredential) async {
          expect(newUserCredential.user, isA<User>());
          User newUser = newUserCredential.user!;

          expect(newUser.uid, isA<String>());
          expect(newUser.email, equals(email));
          expect(newUser.emailVerified, isFalse);
          expect(newUser.isAnonymous, isFalse);
          expect(newUser.uid, equals(FirebaseAuth.instance.currentUser!.uid));

          var additionalUserInfo = newUserCredential.additionalUserInfo!;
          expect(additionalUserInfo, isA<AdditionalUserInfo>());
          expect(additionalUserInfo.isNewUser, isTrue);

          await FirebaseAuth.instance.currentUser?.delete();
        };

        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email,
              testPassword,
            )
            .then(successCallback as Function(UserCredential));
      });

      test('fails if creating a user which already exists', () async {
        await ensureSignedIn(testEmail);
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            testEmail,
            '123456',
          );
          fail('Should have thrown FirebaseAuthException');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('email-already-in-use'));
        } catch (e) {
          fail(e.toString());
        }
      });

      test('fails if creating a user with an invalid email', () async {
        await ensureSignedIn(testEmail);
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            '!!!!!',
            '123456',
          );
          fail('Should have thrown FirebaseAuthException');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('invalid-email'));
        } catch (e) {
          fail(e.toString());
        }
      });

      test('fails if creating a user if providing a weak password', () async {
        await ensureSignedIn(testEmail);
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            generateRandomEmail(),
            '1',
          );
          fail('Should have thrown FirebaseAuthException');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('weak-password'));
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('fetchSignInMethodsForEmail()', () {
      test('should return password provider for an email address', () async {
        var providers =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(testEmail);
        expect(providers, isList);
        expect(providers.contains('password'), isTrue);
      });

      test('should return empty array for a not found email', () async {
        var providers = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(generateRandomEmail());

        expect(providers, isList);
        expect(providers, isEmpty);
      });

      test('throws for a bad email address', () async {
        try {
          await FirebaseAuth.instance.fetchSignInMethodsForEmail('foobar');
          fail('Should have thrown');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('invalid-email'));
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('sendPasswordResetEmail()', () {
      test('should not error', () async {
        var email = generateRandomEmail();

        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email,
            testPassword,
          );

          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          await FirebaseAuth.instance.currentUser!.delete();
        } catch (e) {
          await FirebaseAuth.instance.currentUser!.delete();
          fail(e.toString());
        }
      });

      test('fails if the user could not be found', () async {
        try {
          await FirebaseAuth.instance
              .sendPasswordResetEmail(email: 'does-not-exist@bar.com');
          fail('Should have thrown');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('user-not-found'));
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('languageCode', () {
      test('should change the language code', () async {
        FirebaseAuth.instance.setLanguageCode('en');

        expect(FirebaseAuth.instance.languageCode, equals('en'));
      });

      test(
        'should allow null value and set to null',
        () async {
          FirebaseAuth.instance.setLanguageCode(null);

          expect(FirebaseAuth.instance.languageCode, null);
        },
      );
    });

    group('signInAnonymously()', () {
      test('should sign in anonymously', () async {
        Future successCallback(UserCredential currentUserCredential) async {
          var currentUser = currentUserCredential.user!;

          expect(currentUser, isA<User>());
          expect(currentUser.uid, isA<String>());
          expect(currentUser.email, isNull);
          expect(currentUser.isAnonymous, isTrue);
          expect(
            currentUser.uid,
            equals(FirebaseAuth.instance.currentUser!.uid),
          );

          var additionalUserInfo = currentUserCredential.additionalUserInfo;
          expect(additionalUserInfo, isInstanceOf<Object>());

          await FirebaseAuth.instance.signOut();
        }

        final userCred = await FirebaseAuth.instance.signInAnonymously();
        await successCallback(userCred);
      });
    });

    group('signInWithPhoneNumber() ', () {
      test('should fail with invalid phone number', () async {
        Future<Exception> getError() async {
          final completer = Completer<FirebaseAuthException>();

          unawaited(
            FirebaseAuth.instance
                .signInWithPhoneNumber('foo')
                .then((_) => completer
                    .completeError(Exception('Should not have been called')))
                .catchError((e, _) => completer.complete(e)),
          );

          return completer.future;
        }

        final e = await getError();
        expect(e, isA<FirebaseAuthException>());

        final exception = e as FirebaseAuthException;
        expect(exception.code, equals('invalid-phone-number'));
      });

      test('should verify phone number', () async {
        const testPhoneNumber = '+447444555666';

        Future<ConfirmationResult> getVerificationId() async {
          final completer = Completer<ConfirmationResult>();

          unawaited(
            FirebaseAuth.instance
                .signInWithPhoneNumber(testPhoneNumber)
                .then(completer.complete)
                .catchError((e, _) => completer.completeError(e)),
          );

          return completer.future;
        }

        final confirmationResult = await getVerificationId();

        final verificationCode =
            await emulatorPhoneVerificationCode(testPhoneNumber);

        final credential = await confirmationResult.confirm(verificationCode!);

        expect(credential, isA<UserCredential>());
      });
      test('should link anonymous with phone number', () async {
        const testPhoneNumber = '+447444555666';
        await FirebaseAuth.instance.signInAnonymously();

        Future<ConfirmationResult> getVerificationId() async {
          final completer = Completer<ConfirmationResult>();

          unawaited(
            FirebaseAuth.instance.currentUser
                ?.linkWithPhoneNumber(testPhoneNumber)
                .then(completer.complete)
                .catchError((e, _) => completer.completeError(e)),
          );

          return completer.future;
        }

        final confirmationResult = await getVerificationId();

        final verificationCode =
            await emulatorPhoneVerificationCode(testPhoneNumber);

        final credential = await confirmationResult.confirm(verificationCode!);

        expect(credential, isA<UserCredential>());
      });
      test('should link email with phone number', () async {
        const testPhoneNumber = '+447444555666';

        await FirebaseAuth.instance
            .signInWithEmailAndPassword(testEmail, testPassword);

        Future<ConfirmationResult> getVerificationId() async {
          final completer = Completer<ConfirmationResult>();

          unawaited(
            FirebaseAuth.instance.currentUser
                ?.linkWithPhoneNumber(testPhoneNumber)
                .then(completer.complete)
                .catchError((e, _) => completer.completeError(e)),
          );

          return completer.future;
        }

        final confirmationResult = await getVerificationId();

        final verificationCode =
            await emulatorPhoneVerificationCode(testPhoneNumber);

        final credential = await confirmationResult.confirm(verificationCode!);

        expect(
          credential.user?.providerData.map((e) => e.providerId).toList(),
          unorderedEquals(['password', 'phone']),
        );
      });
    });

    group('signInWithCredential()', () {
      test('should login with email and password', () async {
        var credential = EmailAuthProvider.credential(
          email: testEmail,
          password: testPassword,
        );
        await FirebaseAuth.instance
            .signInWithCredential(credential)
            .then(commonSuccessCallback);
      });

      test('throws if login user is disabled', () async {
        var credential = EmailAuthProvider.credential(
          email: testDisabledEmail,
          password: testPassword,
        );

        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('user-disabled'));
          expect(
            e.message,
            equals(
              'The user account has been disabled by an administrator.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });

      test('throws if login password is incorrect', () async {
        var credential =
            EmailAuthProvider.credential(email: testEmail, password: 'sowrong');
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('wrong-password'));
          expect(
            e.message,
            equals(
              'The password is invalid or the user does not have a password.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });

      test('throws if login user is not found', () async {
        var credential = EmailAuthProvider.credential(
          email: generateRandomEmail(),
          password: testPassword,
        );
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('user-not-found'));
          expect(
            e.message,
            equals(
              'There is no user record corresponding to this identifier. The user may have been deleted.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('signInWithEmailAndPassword()', () {
      test('should login with email and password', () async {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              testEmail,
              testPassword,
            )
            .then(commonSuccessCallback);
      });

      test('throws if login user is disabled', () async {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            testDisabledEmail,
            testPassword,
          );
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('user-disabled'));
          expect(
            e.message,
            equals(
              'The user account has been disabled by an administrator.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });

      test('throws if login password is incorrect', () async {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            testEmail,
            'sowrong',
          );
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('wrong-password'));
          expect(
            e.message,
            equals(
              'The password is invalid or the user does not have a password.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });

      test('throws if login user is not found', () async {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            generateRandomEmail(),
            testPassword,
          );
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('user-not-found'));
          expect(
            e.message,
            equals(
              'There is no user record corresponding to this identifier. The user may have been deleted.',
            ),
          );
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    group('signInWithCustomToken()', () {
      test('signs in with custom auth token', () async {
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

        final customToken = emulatorCreateCustomToken(uid, claims: claims);

        final customTokenUserCredential =
            await FirebaseAuth.instance.signInWithCustomToken(customToken);

        expect(customTokenUserCredential.user!.uid, equals(uid));
        expect(FirebaseAuth.instance.currentUser!.uid, equals(uid));

        final idTokenResult =
            await FirebaseAuth.instance.currentUser!.getIdTokenResult();

        expect(idTokenResult.claims!['roles'], isA<List>());
        expect(idTokenResult.claims!['roles'][0], isA<Map>());
        expect(idTokenResult.claims!['roles'][0]['role'], 'member');
      });
    });

    group('signOut()', () {
      test('should sign out', () async {
        await ensureSignedIn(testEmail);
        expect(FirebaseAuth.instance.currentUser, isA<User>());
        await FirebaseAuth.instance.signOut();
        expect(FirebaseAuth.instance.currentUser, isNull);
      });
    });

    group('verifyPasswordResetCode()', () {
      test('throws on invalid code', () async {
        try {
          await FirebaseAuth.instance.verifyPasswordResetCode('!!!!!!');
          fail('Should have thrown');
        } on FirebaseException catch (e) {
          expect(e.code, equals('invalid-action-code'));
        } catch (e) {
          fail(e.toString());
        }
      });
    });

    // group('setSettings()', () {
    //   test(
    //     'throws argument error if phoneNumber & smsCode have not been set simultaneously',
    //     () async {
    //       String message =
    //           "The [smsCode] and the [phoneNumber] must both be either 'null' or a 'String''.";
    //       await expectLater(
    //         FirebaseAuth.instance.setSettings(phoneNumber: '123456'),
    //         throwsA(
    //           isA<ArgumentError>()
    //               .having((e) => e.message, 'message', contains(message)),
    //         ),
    //       );

    //       await expectLater(
    //         FirebaseAuth.instance.setSettings(smsCode: '123456'),
    //         throwsA(
    //           isA<ArgumentError>()
    //               .having((e) => e.message, 'message', contains(message)),
    //         ),
    //       );
    //     },
    //   );
    // });
  });
}
