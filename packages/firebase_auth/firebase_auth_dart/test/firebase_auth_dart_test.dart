// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_dynamic_calls
import 'dart:async';

import 'package:async/async.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'firebase_auth_dart_test.mocks.dart';
import 'test_utils.dart';

@GenerateMocks([User, FirebaseAuth, UserCredential])
void main() {
  late FirebaseAuth auth;
  late FirebaseAuth fakeAuth;
  final user = MockUser();
  final userCred = MockUserCredential();

  late StreamQueue<User?> authStateChanges;
  late StreamQueue<User?> idTokenChanges;
  group('$FirebaseAuth', () {
    setUpAll(() async {
      const options = FirebaseOptions(
          apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
          authDomain: 'react-native-firebase-testing.firebaseapp.com',
          databaseURL: 'https://react-native-firebase-testing.firebaseio.com',
          projectId: 'react-native-firebase-testing',
          storageBucket: 'react-native-firebase-testing.appspot.com',
          messagingSenderId: '448618578101',
          appId: '1:448618578101:web:0b650370bb29e29cac3efc',
          measurementId: 'G-F79DJ0VFGS');

      await Firebase.initializeApp(options: options);

      auth = FirebaseAuth.instance;

      if (useEmulator) {
        await auth.useAuthEmulator();
      }

      authStateChanges = StreamQueue(auth.authStateChanges());
      idTokenChanges = StreamQueue(auth.idTokenChanges());
    });

    setUp(() async {
      if (useEmulator) {
        await emulatorClearAllUsers();
      }
      await ensureSignedOut();

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

    group('Email and password ', () {
      test('sign-in updates currentUser and events.', () async {
        final credential = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        expect(credential, isA<UserCredential>());
        expect(credential.user!.email, equals(mockEmail));
        expect(await authStateChanges.next, isA<User>());
        expect(await idTokenChanges.next, isA<User>());

        await auth.signOut();
      });
      test('should throw.', () async {
        expect(
          () => auth.signInWithEmailAndPassword(mockEmail, mockPassword),
          throwsA(isA<FirebaseAuthException>()
              .having((e) => e.code, 'error code', 'email-not-found')),
        );
      });
      test('sign-out.', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        await auth.signOut();

        expect(auth.currentUser, isNull);
        expect(await authStateChanges.next, isNull);
        expect(await idTokenChanges.next, isNull);
      });
    });

    group('Anonymous ', () {
      test('sign-up.', () async {
        await auth.signInAnonymously();

        expect(auth.currentUser!.isAnonymous, true);
        expect(auth.currentUser!.email, isNull);
        expect((await auth.currentUser!.getIdTokenResult()).signInProvider,
            'anonymous');

        expect(await authStateChanges.next, isA<User>());
        expect(await idTokenChanges.next, isA<User>());
      });
      test(
        'sign-up return current user if already sign-in anonymously.',
        () async {
          final credential = await auth.signInAnonymously();

          expect(credential.user!.isAnonymous, true);
          expect(credential.credential!.providerId, 'anonymous');

          expect(credential.user, equals(auth.currentUser));
        },
      );
      test('sign-out.', () async {
        await auth.signInAnonymously();
        await auth.signOut();

        expect(auth.currentUser, isNull);
        expect(await authStateChanges.next, isNull);
        expect(await idTokenChanges.next, isNull);
      });
    });

    group('signInWithCredential()', () {
      test('Google', () {});
      test('Twitter', () {});
      test('Facebook', () {});
    });
    group('fetchSignInMethodsForEmail() ', () {
      setUp(() async {
        await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );
      });
      test('email with pssaword provider.', () async {
        await expectLater(
          auth.fetchSignInMethodsForEmail(mockEmail),
          completion(['password']),
        );
      });

      test('invalid email throws.', () {
        expect(
          () => auth.fetchSignInMethodsForEmail('foo'),
          throwsA(
            isA<FirebaseAuthException>().having((p0) => p0.code,
                'invalid identifier code', 'invalid-identifier'),
          ),
        );
      });
      test('empty email throws.', () {
        expect(
          () => auth.fetchSignInMethodsForEmail(''),
          throwsA(
            isA<FirebaseAuthException>().having((p0) => p0.code,
                'invalid identifier code', 'missing-identifier'),
          ),
        );
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

        final cred = await auth.signInWithCustomToken(token);

        expect(auth.currentUser, equals(cred.user));
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

    group('signInWithPhoneNumber() ', () {
      test('should fail with invalid phone number', () async {
        Future<Exception> getError() async {
          final completer = Completer<FirebaseAuthException>();

          unawaited(
            auth
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
            auth
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
        await auth.signInAnonymously();

        Future<ConfirmationResult> getVerificationId() async {
          final completer = Completer<ConfirmationResult>();

          unawaited(
            auth.currentUser
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

        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        Future<ConfirmationResult> getVerificationId() async {
          final completer = Completer<ConfirmationResult>();

          unawaited(
            auth.currentUser
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
    group('unlink()', () {
      //TODO: implement and test unlink
      test('should unlink phone number', () async {});
    });

    group('Use emulator ', () {
      test('returns project config.', () async {
        expect(auth.useAuthEmulator(), completes);
      });
    });

    group('Set languageCode ', () {
      test('updates the instance laguage code.', () async {
        auth.setLanguageCode('ar');

        expect(
          auth.languageCode,
          equals('ar'),
        );
      });
    });

    group('IdToken ', () {
      setUp(() async {
        await emulatorClearAllUsers();
      });
      test('getIdTokenResult()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );
        final token = await cred.user!.getIdTokenResult();
        expect(token, isA<IdTokenResult>());
      });
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
      test('sendPasswordResetEmail().', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        await expectLater(
          auth.sendPasswordResetEmail(email: mockEmail),
          completion(mockEmail),
        );
      });
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
      test('confirmPasswordReset() throws.', () async {
        await expectLater(
          auth.confirmPasswordReset(mockOobCode, mockPassword),
          throwsA(isA<FirebaseAuthException>()
              .having((p0) => p0.code, 'invalid oob code', 'invalid-oob-code')),
        );
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
      test('updateEmail()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        await cred.user!.updateEmail('test+1@test.com');

        expect(auth.currentUser!.email, equals('test+1@test.com'));

        // Access token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));

        expect(
          auth.signInWithEmailAndPassword(
            mockEmail,
            mockPassword,
          ),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', 'email-not-found'),
          ),
        );
      });
      test('updateDisplayName() & updatePhotoURL()', () async {
        await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        await auth.currentUser!.updateDisplayName(displayName);
        await auth.currentUser!.updatePhotoURL(photoURL);

        expect(auth.currentUser!.displayName, equals(displayName));
        expect(auth.currentUser!.photoURL, equals(photoURL));

        // Access token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));
      });
      test('updatePassword()', () async {
        await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        // update the password
        await auth.currentUser!.updatePassword('newPassword');

        await auth.signInWithEmailAndPassword(mockEmail, 'newPassword');

        // id token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));
      });
      test('delete()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final user = cred.user;

        await user?.delete();

        expect(auth.currentUser, isNull);
        expect(
          user?.delete(),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', 'user-not-found'),
          ),
        );
        expect(
          auth.signInWithEmailAndPassword(
            mockEmail,
            mockPassword,
          ),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', 'email-not-found'),
          ),
        );
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
      test('.metadata', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        final metadata = auth.currentUser!.metadata!;

        expect(metadata.creationTime!.isBefore(DateTime.now()), isTrue);
        expect(metadata.lastSignInTime!.isBefore(DateTime.now()), isTrue);
      });
      test('.providerData', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        expect(
          auth.currentUser!.providerData.isNotEmpty,
          isTrue,
        );
      });
    });

    group('StorageBox ', () {
      test('put a new value.', () {
        final box = StorageBox.instanceOf('box');
        box.putValue('key', '123');

        expect(box.getValue('key'), '123');
      });
      test('put a null value does not add the value.', () {
        final box = StorageBox.instanceOf('box');
        box.putValue('key_2', null);
        expect(
          () => box.getValue('key_2'),
          throwsA(isA<StorageBoxException>()),
        );
      });
      test('get a key that does not exist.', () {
        final box = StorageBox.instanceOf('box');
        expect(
          () => box.getValue('random_key'),
          throwsA(isA<StorageBoxException>()),
        );
      });
      test('get a key from a box that does not exist.', () {
        final box = StorageBox.instanceOf('box_');
        expect(
          () => box.getValue('key'),
          throwsA(isA<StorageBoxException>()),
        );
      });
    });
  });
}
