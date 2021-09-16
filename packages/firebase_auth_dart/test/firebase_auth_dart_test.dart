import 'dart:io';

import 'package:firebase_auth_dart/src/interop/auth.dart';
import 'package:firebase_auth_dart/src/interop/exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // ↓ required to avoid HTTP error 400 mocked returns
    HttpOverrides.global = null;
  });
  group('IPAuth', () {
    final auth = IPAuth(
      settings: IPAuthSettings(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      ),
    );
    test('Successful sign-in with email and password', () async {
      const email = 'ipauth@test.com';
      const password = '123qwe';

      final user = await auth.signInWithEmailAndPassword(email, password);

      expect(
        user.uid,
        'oHPElljO79Zxju4JYFTag42aOXh2',
      );
    });
    test("User doesn't exist", () async {
      const email = 'ghostuser@test.com';
      const password = '123qwsdgsdfg';
      try {
        await auth.signInWithEmailAndPassword(email, password);
      } catch (exception) {
        expect(
          exception,
          isA<IPException>().having(
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
          isA<IPException>().having(
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
          isA<IPException>().having(
            (error) => error.code,
            'error code',
            ErrorCode.userDisabled,
          ),
        );
      }
    });
  });
}
