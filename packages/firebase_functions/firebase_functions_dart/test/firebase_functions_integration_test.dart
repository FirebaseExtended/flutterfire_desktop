// ignore_for_file: require_trailing_commas, avoid_dynamic_calls

// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_functions_dart/firebase_functions_dart.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'data.dart' as data;

FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
    );

Future<void> main() async {
  setUpAll(() async {
    await Firebase.initializeApp(options: firebaseOptions);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  });

  group('FirebaseFunctionsIntegration', () {
    group('HttpsCallable', () {
      late final HttpsCallable httpsCallable;

      setUpAll(() async {
        final functions = FirebaseFunctions.instance;
        httpsCallable = functions.httpsCallable('foo');
      });
      group('call()', () {
        test('parameter validation accepts null values', () async {
          expect((await httpsCallable.call(null)).data, isNull);
        });

        test('parameter validation accepts string values', () async {
          final result = await httpsCallable.call('foo');
          expect(
            result.data,
            allOf(
              isA<String>(),
              equals('foo'),
            ),
          );
        });

        test('parameter validation accepts numeric values', () async {
          final result = await httpsCallable.call(123);
          expect(result.data, equals(123));
        });

        test('parameter validation accepts boolean values', () async {
          final trueResult = await httpsCallable.call(true);
          final falseResult = await httpsCallable.call(false);
          expect(trueResult.data, isTrue);
          expect(falseResult.data, isFalse);
        });

        test('parameter validation accepts List values', () async {
          final result = await httpsCallable.call(data.list);
          expect(
            result.data,
            allOf(
              isA<List>(),
              equals(data.list),
            ),
          );
        });

        test('parameter validation accepts nested List values', () async {
          final result = await httpsCallable.call(data.deepList);
          expect(
            result.data,
            allOf(
              isA<List>(),
              equals(data.deepList),
            ),
          );
        });

        test('parameter validation accepts Map values', () async {
          final result = await httpsCallable.call(data.map);
          expect(
            result.data,
            allOf(
              isA<Map>(),
              equals(data.map),
            ),
          );
        });

        test('parameter validation accepts nested Map values', () async {
          final result = await httpsCallable.call(data.deepMap);
          expect(
            result.data,
            allOf(
              isA<Map>(),
              equals(data.deepMap),
            ),
          );
        });

        test('parameter validation throws if any other type of data is passed',
            () async {
          expect(() {
            return httpsCallable.call(() => {});
          }, throwsA(isA<AssertionError>()));

          // Check nested values in Lists or Maps also throw if invalid:
          expect(() {
            return httpsCallable.call({
              'valid': 'hello world',
              'not_valid': () => {},
            });
          }, throwsA(isA<AssertionError>()));
          expect(() {
            return httpsCallable.call(['valid', () => {}]);
          }, throwsA(isA<AssertionError>()));
        });
      });
    });
    group('Exceptions', () {
      late final HttpsCallable httpsCallable;

      setUpAll(() async {
        final functions = FirebaseFunctions.instance;
        httpsCallable = functions.httpsCallable('testExceptions');
      });

      test('Returning a non 200 status throws', () {
        expect(
          () => httpsCallable.call('bad-status'),
          throwsA(isA<FirebaseFunctionsException>()
              .having((e) => e.code, 'code', contains('invalid-argument'))),
        );
      });
    });

    group('Authentication', () {
      late final HttpsCallable httpsCallable;
      late final FirebaseApp app;
      setUp(() async {
        await emulatorClearAllUsers();
      });
      setUpAll(() async {
        app = await Firebase.initializeApp(
            options: firebaseOptions, name: 'auth_firestore_integration');
        final functions = FirebaseFunctions.instanceFor(app: app);
        functions.useFunctionsEmulator('localhost', 5001);
        httpsCallable = functions.httpsCallable('testFunctionAuthorized');
      });

      tearDown(() {
        // Clear auth storage
        StorageBox.instanceOf(app.options.projectId)
            .putValue('${app.options.apiKey}:${app.name}', null);
      });
      test('unauthorized access throws', () async {
        expect(
          () => httpsCallable.call('unauthorized'),
          throwsA(isA<FirebaseFunctionsException>()
              .having((e) => e.code, 'code', contains('unauthenticated'))),
        );
      });

      test('authorized access succeeds', () async {
        final auth = FirebaseAuth.instanceFor(app: app);
        await auth.useAuthEmulator();
        await auth.signInAnonymously();
        final result = await httpsCallable.call('auth');
        expect(result.data, equals('authorized'));
      });
    });
  });
}

/// Deletes all users from the Auth emulator.
Future<void> emulatorClearAllUsers() async {
  //await realAuth.signOut();
  await http.delete(
    Uri.parse(
        'http://localhost:9099/emulator/v1/projects/react-native-firebase-testing/accounts'),
    headers: {
      'Authorization': 'Bearer owner',
    },
  );
}
