// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:drive/drive.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';

import 'test_utils.dart';

void setupTests() {
  group('$User', () {
    String email = generateRandomEmail();

    group('IdToken ', () {
      test('should return a token.', () async {
        // Setup
        User? user;

        // Create a new mock user account.
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
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
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
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
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
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
              'FirebaseAuthException with code: no-current-user',
              'no-current-user',
            ),
          ),
        );
      });

      test('should return a valid IdTokenResult Object.', () async {
        // Setup
        User? user;

        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
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

    group('linkWithCredential()', () {
      test('should link anonymous account <-> email account', () async {
        await FirebaseAuth.instance.signInAnonymously();
        String currentUID = FirebaseAuth.instance.currentUser!.uid;

        UserCredential linkedUserCredential =
            await FirebaseAuth.instance.currentUser!.linkWithCredential(
          EmailAuthProvider.credential(
            email: email,
            password: testPassword,
          ),
        );

        User linkedUser = linkedUserCredential.user!;
        expect(linkedUser.email, equals(email));
        expect(
          linkedUser.email,
          equals(FirebaseAuth.instance.currentUser!.email),
        );
        expect(linkedUser.uid, equals(currentUID));
        expect(linkedUser.isAnonymous, isFalse);
      });

      test('should error on link anon <-> email if email already exists',
          () async {
        // Setup
        await FirebaseAuth.instance.signInAnonymously();

        // Test
        try {
          await FirebaseAuth.instance.currentUser!.linkWithCredential(
            EmailAuthProvider.credential(
              email: testEmail,
              password: testPassword,
            ),
          );
        } on FirebaseAuthException catch (e) {
          // Assertions
          expect(e.code, 'email-already-in-use');
          expect(
            e.message,
            'The email address is already in use by another account.',
          );

          // clean up
          await FirebaseAuth.instance.currentUser!.delete();
          return;
        }

        fail('should have thrown an error');
      });

      test(
        'should link anonymous account <-> phone account',
        () async {
          await FirebaseAuth.instance.signInAnonymously();

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

          String storedVerificationId =
              (await getVerificationId()).verificationId;

          await FirebaseAuth.instance.currentUser!.linkWithCredential(
            PhoneAuthProvider.credential(
              verificationId: storedVerificationId,
              smsCode: (await emulatorPhoneVerificationCode(testPhoneNumber))!,
            ),
          );
          expect(FirebaseAuth.instance.currentUser, equals(isA<User>()));
          expect(
            FirebaseAuth.instance.currentUser!.phoneNumber,
            equals(testPhoneNumber),
          );
          expect(
            FirebaseAuth.instance.currentUser!.providerData,
            equals(isA<List<UserInfo>>()),
          );
          expect(
            FirebaseAuth.instance.currentUser!.providerData.length,
            equals(1),
          );
          expect(
            FirebaseAuth.instance.currentUser!.providerData[0],
            equals(isA<UserInfo>()),
          );
          expect(FirebaseAuth.instance.currentUser!.isAnonymous, isFalse);

          await FirebaseAuth.instance.currentUser
              ?.unlink(PhoneAuthProvider.PROVIDER_ID);
          await FirebaseAuth.instance.currentUser?.delete();
        },
      );

      test(
        'should error on link anonymous account <-> phone account if invalid credentials',
        () async {
          // Setup
          await FirebaseAuth.instance.signInAnonymously();

          try {
            await FirebaseAuth.instance.currentUser!.linkWithCredential(
              PhoneAuthProvider.credential(
                verificationId: 'test',
                smsCode: 'test',
              ),
            );
          } on FirebaseAuthException catch (e) {
            expect(e.code, equals('invalid-verification-id'));
            expect(
              e.message,
              equals(
                'The verification ID used to create the phone auth credential is invalid.',
              ),
            );
            return;
          } catch (e) {
            fail('should have thrown an FirebaseAuthException');
          }

          fail('should have thrown an error');
        },
      );
    });

    group('reauthenticateWithCredential()', () {
      test('should reauthenticate correctly', () async {
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        User initialUser = FirebaseAuth.instance.currentUser!;

        // Test
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: testPassword);
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(credential);

        // Assertions
        User currentUser = FirebaseAuth.instance.currentUser!;
        expect(currentUser.email, equals(email));
        expect(currentUser.uid, equals(initialUser.uid));
      });

      test('should throw user-mismatch ', () async {
        // Setup
        const emailAlready = 'test+2@gmail.com';

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          emailAlready,
          testPassword,
        );

        try {
          // Test
          final credential = EmailAuthProvider.credential(
            email: testEmail,
            password: testPassword,
          );
          await FirebaseAuth.instance.currentUser!
              .reauthenticateWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // Assertions
          expect(e.code, equals('user-mismatch'));
          expect(
            e.message,
            equals(
              'The supplied credentials do not correspond to the previously signed in user.',
            ),
          );
          await FirebaseAuth.instance.currentUser!.delete(); //clean up
          return;
        } catch (e) {
          fail('should have thrown an FirebaseAuthException');
        }

        fail('should have thrown an error');
      });

      test('should throw user-not-found or user-mismatch ', () async {
        // Setup
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        final user = userCredential.user!;

        // Test
        final credential = EmailAuthProvider.credential(
          email: 'userdoesnotexist@foobar.com',
          password: testPassword,
        );
        await expectLater(
          user.reauthenticateWithCredential(credential),
          throwsA(
            isA<FirebaseAuthException>().having(
              (p0) => p0.code,
              'Throws user-mismatch exception',
              'user-mismatch',
            ),
          ),
        );
      });

      // TODO error codes no longer match when using emulator.
      // test('should throw invalid-email ', () async {
      //   // Setup
      //   await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //       email: email, password: testPassword);
      //
      //   try {
      //     // Test
      //     AuthCredential credential = EmailAuthProvider.credential(
      //         email: 'invalid', password: testPassword);
      //     await FirebaseAuth.instance.currentUser
      //         .reauthenticateWithCredential(credential);
      //   } on FirebaseAuthException catch (e) {
      //     // Assertions
      //     expect(e.code, equals('invalid-email'));
      //     expect(e.message, equals('The email address is badly formatted.'));
      //     return;
      //   } catch (e) {
      //     fail('should have thrown an FirebaseAuthException');
      //   }
      //
      //   fail('should have thrown an error');
      // });

      test('should throw wrong-password ', () async {
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );

        try {
          // Test
          AuthCredential credential = EmailAuthProvider.credential(
            email: email,
            password: 'WRONG_testPassword',
          );
          await FirebaseAuth.instance.currentUser!
              .reauthenticateWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // Assertions
          expect(e.code, equals('wrong-password'));
          expect(
            e.message,
            equals(
              'The password is invalid or the user does not have a password.',
            ),
          );
          return;
        } catch (e) {
          fail('should have thrown an FirebaseAuthException');
        }

        fail('should have thrown an error');
      });
    });

    group('reload()', () {
      test('should not error', () async {
        await FirebaseAuth.instance.signInAnonymously();
        try {
          await FirebaseAuth.instance.currentUser!.reload();
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          fail('should not throw error');
        }
        expect(FirebaseAuth.instance.currentUser, isNull);
      });
    });

    group('sendEmailVerification()', () {
      test('should not error', () async {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          generateRandomEmail(),
          testPassword,
        );
        try {
          await FirebaseAuth.instance.currentUser!.sendEmailVerification();
        } catch (e) {
          fail('should not throw error');
        }
        expect(FirebaseAuth.instance.currentUser, isNotNull);
      });

      test(
        'should work with actionCodeSettings',
        () async {
          // Setup
          // ActionCodeSettings actionCodeSettings = ActionCodeSettings(
          //   handleCodeInApp: true,
          //   url: 'https://flutterfire-e2e-tests.firebaseapp.com/foo',
          // );
          // await FirebaseAuth.instance.createUserWithEmailAndPassword(
          //    generateRandomEmail(),
          //    testPassword,
          // );

          // // Test
          // try {
          //   await FirebaseAuth.instance.currentUser!
          //       .sendEmailVerification(actionCodeSettings);
          // } catch (error) {
          //   fail('$error');
          // }
          // expect(FirebaseAuth.instance.currentUser, isNotNull);
        },
      );
    });

    group('unlink()', () {
      test('should unlink the email address', () async {
        // Setup
        await FirebaseAuth.instance.signInAnonymously();

        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: testPassword);
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

        // verify user is linked
        User linkedUser = FirebaseAuth.instance.currentUser!;
        expect(linkedUser.email, email);
        expect(linkedUser.providerData, isA<List<UserInfo>>());
        expect(linkedUser.providerData.length, equals(1));

        // Test
        await FirebaseAuth.instance.currentUser!
            .unlink(EmailAuthProvider.PROVIDER_ID);

        // Assertions
        User unlinkedUser = FirebaseAuth.instance.currentUser!;
        expect(unlinkedUser.providerData, isA<List<UserInfo>>());
        expect(unlinkedUser.providerData.length, equals(0));
      });

      test('should throw error if provider id given does not exist', () async {
        // Setup
        await FirebaseAuth.instance.signInAnonymously();

        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: testPassword);
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

        // verify user is linked
        User linkedUser = FirebaseAuth.instance.currentUser!;
        expect(linkedUser.email, email);

        await expectLater(
          FirebaseAuth.instance.currentUser!.unlink('invalid'),
          throwsA(
            isA<FirebaseAuthException>().having(
              (p0) => p0.code,
              'Throws no-such-provider exception',
              'no-such-provider',
            ),
          ),
        );
      });

      test('should throw error if user does not have this provider linked',
          () async {
        // Setup
        await FirebaseAuth.instance.signInAnonymously();
        // Test
        await expectLater(
          FirebaseAuth.instance.currentUser!
              .unlink(EmailAuthProvider.PROVIDER_ID),
          throwsA(
            isA<FirebaseAuthException>().having(
              (p0) => p0.code,
              'Throws no-such-provider exception',
              'no-such-provider',
            ),
          ),
        );
      });
    });

    group('updateEmail()', () {
      test('should update the email address', () async {
        String emailBefore = generateRandomEmail();
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          emailBefore,
          testPassword,
        );
        expect(FirebaseAuth.instance.currentUser!.email, equals(emailBefore));

        // Update user email
        await FirebaseAuth.instance.currentUser!.updateEmail(email);
        expect(FirebaseAuth.instance.currentUser!.email, equals(email));
      });
    });

    group('updatePassword()', () {
      test('should update the password', () async {
        String pass = '${testPassword}1';
        String pass2 = '${testPassword}2';
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email, pass);

        // Update user password
        await FirebaseAuth.instance.currentUser!.updatePassword(pass2);

        // // Sign out
        await FirebaseAuth.instance.signOut();

        // Log in with the new password
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email,
          pass2,
        );

        // Assertions
        expect(FirebaseAuth.instance.currentUser, isA<Object>());
        expect(FirebaseAuth.instance.currentUser!.email, equals(email));
      });
      test('should throw error if password is weak', () async {
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );

        // Test
        try {
          // Update user password
          await FirebaseAuth.instance.currentUser!.updatePassword('weak');
        } on FirebaseAuthException catch (e) {
          expect(e.code, 'weak-password');
          expect(e.message, 'Password should be at least 6 characters.');
          return;
        } catch (e) {
          fail('should have thrown an FirebaseAuthException error');
        }
        fail('should have thrown an error');
      });
    });

    group('refreshToken', () {
      test(
        'should return a token',
        () async {
          // Setup
          await FirebaseAuth.instance.signInAnonymously();

          // Test
          FirebaseAuth.instance.currentUser!.refreshToken;

          // Assertions
          expect(
            FirebaseAuth.instance.currentUser!.refreshToken,
            isA<String>(),
          );
          expect(
            FirebaseAuth.instance.currentUser!.refreshToken!.isEmpty,
            isFalse,
          );
        },
      );
    });

    group('user.metadata', () {
      test(
          "should have the properties 'lastSignInTime' & 'creationTime' which are ISO strings",
          () async {
        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          generateRandomEmail(),
          testPassword,
        );
        User user = FirebaseAuth.instance.currentUser!;

        // Test
        UserMetadata? metadata = user.metadata;

        // Assertions
        expect(metadata?.lastSignInTime, isA<DateTime>());
        expect(metadata?.lastSignInTime!.year, DateTime.now().year);
        expect(metadata?.creationTime, isA<DateTime>());
        expect(metadata?.creationTime!.year, DateTime.now().year);
      });
    });

    group('updateDisplayName', () {
      test('updates the user displayName without impacting the photoURL',
          () async {
        // First create a user with a photo
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        await FirebaseAuth.instance.currentUser!.updateDisplayName('Mona Lisa');
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(
          'http://photo.url/test.jpg',
        );
        await FirebaseAuth.instance.currentUser!.reload();

        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          'http://photo.url/test.jpg',
        );
        expect(
          FirebaseAuth.instance.currentUser!.displayName,
          'Mona Lisa',
        );

        await FirebaseAuth.instance.currentUser!
            .updateDisplayName('John Smith');
        await FirebaseAuth.instance.currentUser!.reload();

        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          'http://photo.url/test.jpg',
        );
        expect(
          FirebaseAuth.instance.currentUser!.displayName,
          'John Smith',
        );
      });

      test(
        'can set the displayName to null',
        () async {
          // First create a user with a photo
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email,
            testPassword,
          );
          await FirebaseAuth.instance.currentUser!
              .updateDisplayName('Mona Lisa');
          await FirebaseAuth.instance.currentUser!.reload();

          // Just checking that the user indeed had a name before we set it to null
          expect(
            FirebaseAuth.instance.currentUser!.displayName,
            isNotNull,
          );

          await FirebaseAuth.instance.currentUser!.updateDisplayName(null);
          await FirebaseAuth.instance.currentUser!.reload();

          expect(
            FirebaseAuth.instance.currentUser!.displayName,
            isNull,
          );
        },
      );
    });

    group('updatePhotoURL', () {
      test('updates the photoURL without impacting the displayName', () async {
        // First create a user with a photo
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        await Future.wait([
          FirebaseAuth.instance.currentUser!.updateDisplayName('Mona Lisa'),
          FirebaseAuth.instance.currentUser!.updatePhotoURL(
            'http://photo.url/test.jpg',
          ),
        ]);
        await FirebaseAuth.instance.currentUser!.reload();

        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          'http://photo.url/test.jpg',
        );
        expect(
          FirebaseAuth.instance.currentUser!.displayName,
          'Mona Lisa',
        );

        await FirebaseAuth.instance.currentUser!.updatePhotoURL(
          'http://photo.url/dash.jpg',
        );
        await FirebaseAuth.instance.currentUser!.reload();

        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          'http://photo.url/dash.jpg',
        );
        expect(
          FirebaseAuth.instance.currentUser!.displayName,
          'Mona Lisa',
        );
      });

      test('can set the photoURL to null', () async {
        // First create a user with a photo
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(
          'http://photo.url/test.jpg',
        );
        await FirebaseAuth.instance.currentUser!.reload();

        // Just checking that the user indeed had a photo before we set it to null
        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          isNotNull,
        );

        await FirebaseAuth.instance.currentUser!.updatePhotoURL(null);
        await FirebaseAuth.instance.currentUser!.reload();

        expect(
          FirebaseAuth.instance.currentUser!.photoURL,
          isNull,
        );
      });
    });

    group('updateProfile()', () {
      test('should update the profile', () async {
        String displayName = 'testName';
        String photoURL = 'http://photo.url/test.jpg';

        // Setup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );

        // Update user profile
        await FirebaseAuth.instance.currentUser!.updateProfile(
          displayName: displayName,
          photoUrl: photoURL,
        );

        await FirebaseAuth.instance.currentUser!.reload();
        User user = FirebaseAuth.instance.currentUser!;

        // Assertions
        expect(user, isA<Object>());
        expect(user.email, email);
        expect(user.displayName, equals(displayName));
        expect(user.photoURL, equals(photoURL));
      });
    });

    group('updatePhoneNumber()', () {
      // TODO this test is now flakey since switching to Auth emulator, consider
      //      rewriting it.
      // test('should update the phone number', () async {
      //   // Setup
      //   await FirebaseAuth.instance.signInAnonymously();
      //
      //   Future<String> getVerificationId() {
      //     Completer completer = Completer<String>();
      //
      //     unawaited(FirebaseAuth.instance.verifyPhoneNumber(
      //       phoneNumber: testPhoneNumber,
      //       verificationCompleted: (PhoneAuthCredential credential) {
      //         fail('Should not have auto resolved');
      //       },
      //       verificationFailed: (FirebaseException e) {
      //         fail('Should not have errored');
      //       },
      //       codeSent: (String verificationId, int resetToken) {
      //         completer.complete(verificationId);
      //       },
      //       codeAutoRetrievalTimeout: (String foo) {},
      //     ));
      //
      //     return completer.future;
      //   }
      //
      //   String storedVerificationId = await getVerificationId();
      //
      //   // Update user profile
      //   await FirebaseAuth.instance.currentUser
      //       .updatePhoneNumber(PhoneAuthProvider.credential(
      //     verificationId: storedVerificationId,
      //     smsCode: await emulatorPhoneVerificationCode(testPhoneNumber),
      //   ));
      //
      //   await FirebaseAuth.instance.currentUser.reload();
      //   User user = FirebaseAuth.instance.currentUser;
      //
      //   // Assertions
      //   expect(user, isA<Object>());
      //   expect(user.phoneNumber, equals(testPhoneNumber));
      // }, skip: kIsWeb || defaultTargetPlatform == TargetPlatform.macOS);

      test(
        'should throw an FirebaseAuthException if verification id is invalid',
        () async {
          // Setup
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email,
            testPassword,
          );

          try {
            // Update user profile
            await FirebaseAuth.instance.currentUser!.updatePhoneNumber(
              PhoneAuthProvider.credential(
                verificationId: 'invalid',
                smsCode: '123456',
              ),
            );
          } on FirebaseAuthException catch (e) {
            expect(e.code, 'invalid-verification-id');
            expect(
              e.message,
              'The verification ID used to create the phone auth credential is invalid.',
            );
            return;
          } catch (e) {
            fail('should have thrown a AssertionError error');
          }

          fail('should have thrown an error');
        },
      );

      // TODO error codes no longer match up on emulator
      // test('should throw an error when verification id is an empty string',
      //     () async {
      //   // Setup
      //   await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //       email: email, password: testPassword);
      //
      //   try {
      //     // Test
      //     await FirebaseAuth.instance.currentUser.updatePhoneNumber(
      //         PhoneAuthProvider.credential(
      //             verificationId: '', smsCode: '123456'));
      //   } on FirebaseAuthException catch (e) {
      //     expect(e.code, 'invalid-verification-id');
      //     expect(e.message,
      //         'The verification ID used to create the phone auth credential is invalid.');
      //     return;
      //   } catch (e) {
      //     fail('should have thrown an FirebaseAuthException error');
      //   }
      //
      //   fail('should have thrown an error');
      // }, skip: kIsWeb || defaultTargetPlatform == TargetPlatform.macOS);
    });

    // TODO fails on emulator but works on live Firebase project
    // group('verifyBeforeUpdateEmail()', () {
    //   test(
    //     'should send verification email',
    //     () async {
    //       await ensureSignedIn(email);
    //       await FirebaseAuth.instance.currentUser.verifyBeforeUpdateEmail(
    //           'updated-test-email@example.com',
    //           ActionCodeSettings(
    //             url: 'http://action-code-test.com',
    //             handleCodeInApp: true,
    //           ));
    //
    //       // Confirm with the Auth emulator that it triggered an email sending code.
    //       final oobCode = await emulatorOutOfBandCode(
    //           email, EmulatorOobCodeType.verifyEmail);
    //       expect(oobCode, isNotNull);
    //       expect(oobCode.email, email);
    //       expect(oobCode.type, EmulatorOobCodeType.verifyEmail);
    //     },
    //   );
    // });

    group('delete()', () {
      test('should delete a user', () async {
        // Setup
        late User user;
        UserCredential userCredential;

        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        user = userCredential.user!;

        // Test
        await user.delete();

        // Assertions
        expect(FirebaseAuth.instance.currentUser, equals(null));
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email,
          testPassword,
        )
            .then((UserCredential userCredential) {
          expect(FirebaseAuth.instance.currentUser!.email, equals(email));
          return;
        }).catchError((Object error) {
          fail('Should have successfully created user after deletion');
        });
      });

      test('should throw an error on delete when no user is signed in',
          () async {
        // Setup
        late User user;
        UserCredential userCredential;

        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email,
          testPassword,
        );
        user = userCredential.user!;

        await FirebaseAuth.instance.signOut();

        try {
          // Test
          await user.delete();
        } on FirebaseAuthException catch (e) {
          // Assertions
          expect(e.code, 'no-current-user');
          expect(e.message, 'No user currently signed in.');

          return;
        } catch (e) {
          fail('Should have thrown an FirebaseAuthException error');
        }

        fail('Should have thrown an error');
      });
    });
  });
}
