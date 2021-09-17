import 'dart:io';

import 'package:firebase_auth_dart/src/interop/dart_auth.dart';
import 'package:firebase_auth_dart/src/interop/dart_exception.dart';
import 'package:firebase_auth_dart/src/interop/dart_user.dart';
import 'package:firebase_auth_dart/src/interop/dart_user_credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // Avoid HTTP error 400 mocked returns
    // TODO(Mais): once done create mock clients
    HttpOverrides.global = null;
  });
  group('IPAuth', () {
    final auth = DartAuth(
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    );
    group('Sign in with email and password', () {
      test('Successful sign-in', () async {
        const email = 'ipauth@test.com';
        const password = '123qwe';

        final user = await auth.signInWithEmailAndPassword(email, password);

        expect(user, isA<DartUserCredential>());
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
        const email = 'ipauth@test.com';
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
        const email = 'ipauth@test.com';
        const password = '123qws';
        final user = await auth.signUpWithEmailAndPassword(email, password);
        expect(user, isA<DartUser>());
      });
      test('User already exists', () async {
        const email = 'ipauth@test.com';
        const password = '123qws';
        try {
          await auth.signUpWithEmailAndPassword(email, password);
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
          await auth.signUpWithEmailAndPassword(email, password);
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
  });
}
