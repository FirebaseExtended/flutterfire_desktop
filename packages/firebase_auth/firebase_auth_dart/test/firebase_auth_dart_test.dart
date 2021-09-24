import 'dart:io';

import 'package:firebase_auth_dart/firebase_auth.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    // Avoid HTTP error 400 mocked returns
    // TODO(pr-Mais): once done create mock clients
    HttpOverrides.global = null;
  });
  group('IPAuth', () {
    final auth = Auth(
      options: AuthOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        projectId: '',
      ),
    );
    group('Sign in/out with email and password', () {
      test('Successful sign-in', () async {
        const email = 'ipauth+10@test.com';
        const password = '123qws';

        final user = await auth.signInWithEmailAndPassword(email, password);

        expect(user, isA<UserCredential>());
      });
      test("User doesn't exist", () async {
        const email = 'ghostuser@test.com';
        const password = '123qws';
        try {
          await auth.signInWithEmailAndPassword(email, password);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.emailNotFound,
            ),
          );
        }
      });
      test('Wrong password', () async {
        const email = 'mais@test.com';
        const password = '123qwsdgsdfg';
        try {
          await auth.signInWithEmailAndPassword(email, password);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.invalidPassword,
            ),
          );
        }
      });
      test('User disabled', () async {
        const email = 'ipauth+1@test.com';
        const password = '123qws';
        try {
          await auth.signInWithEmailAndPassword(email, password);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.userDisabled,
            ),
          );
        }
      });
    });

    group('Sign up with email and password', () {
      test('Successful', () async {
        const email = 'ipauth+10@test.com';
        const password = '123qws';
        final user = await auth.createUserWithEmailAndPassword(email, password);
        expect(user, isA<UserCredential>());
      });
      test('User already exists', () async {
        const email = 'ipauth@test.com';
        const password = '123qws';
        try {
          await auth.createUserWithEmailAndPassword(email, password);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.emailExists,
            ),
          );
        }
      });

      test('Email/password sign-in blocked', () async {
        const email = 'ipauth@test.com';
        const password = '123qws';
        try {
          await auth.createUserWithEmailAndPassword(email, password);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.operationNotAllowed,
            ),
          );
        }
      });
    });

    group('Fetch providers list for email', () {
      test('Providers list of an existing email', () async {
        const email = 'ipauth@test.com';

        final providersList = await auth.fetchSignInMethodsForEmail(email);

        expect(
          providersList,
          isA<List<String>>().having(
            (list) => list[0],
            'first provider',
            'password',
          ),
        );
      });
      test("Exception if email doesn't exist", () async {
        const email = 'fakewichdontexist@test.com';

        try {
          await auth.fetchSignInMethodsForEmail(email);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.invalidEmail,
            ),
          );
        }
      });
      test('Invalid identifier', () async {
        try {
          await auth.fetchSignInMethodsForEmail('');
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>(),
          );
        }
      });
    });

    group('Password reset email', () {
      test('Successfully send an email', () async {
        // place an email which you have access to here
        const email = '';

        final responseEmail = await auth.sendPasswordResetEmail(email);

        expect(
          responseEmail,
          isA<String>().having(
            (email) => email,
            "user's email",
            email,
          ),
        );
      });
      test("Exception if email doesn't exist", () async {
        const email = 'fakewichdontexist@test.com';

        try {
          await auth.sendPasswordResetEmail(email);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.emailNotFound,
            ),
          );
        }
      });
    });

    group('Email link sign in', () {
      test('Successfully send an email', () async {
        // place an email which you have access to here
        const email = 'mais@invertase.io';

        final responseEmail = await auth.sendSignInLinkToEmail(email);

        expect(
          responseEmail,
          email,
        );
      });

      test("Exception if email doesn't exist", () async {
        const email = 'fakewichdontexist@test.com';

        try {
          await auth.sendSignInLinkToEmail(email);
        } catch (exception) {
          expect(
            exception,
            isA<AuthException>().having(
              (error) => error.code,
              'error code',
              ErrorCode.emailNotFound,
            ),
          );
        }
      });
    });
  });
}
