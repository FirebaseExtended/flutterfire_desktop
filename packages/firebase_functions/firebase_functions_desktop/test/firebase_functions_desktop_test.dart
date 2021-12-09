// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_desktop/firebase_core_desktop.dart'
    as core_desktop;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_functions_desktop/firebase_functions_desktop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'data.dart' as data;

FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
    );
Future<void> main() async {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final core = core_desktop.FirebaseCore();
    FirebasePlatform.instance = core;
    Firebase.delegatePackingProperty = core;
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
      ),
    );
    FirebaseFunctionsPlatform.instance = FirebaseFunctionsDesktop(app: app);
  });

  group('FirebaseFunctions', () {
    group('.instance', () {
      test('uses the default FirebaseApp instance', () {
        expect(FirebaseFunctions.instance.app, isA<FirebaseApp>());
        expect(FirebaseFunctions.instance.app.name,
            equals(defaultFirebaseAppName));
      });

      test('uses the default Functions region', () {
        expect(
            FirebaseFunctions.instance.delegate.region, equals('us-central1'));
      });
    });

    group('.instanceFor()', () {
      FirebaseApp? secondaryApp;

      setUpAll(() async {
        secondaryApp = await Firebase.initializeApp(
          name: 'foo',
          options: const FirebaseOptions(
            apiKey: '123',
            appId: '123',
            messagingSenderId: '123',
            projectId: '123',
          ),
        );
      });

      test('accepts a secondary FirebaseApp instance', () async {
        final functionsSecondary =
            FirebaseFunctions.instanceFor(app: secondaryApp);
        expect(functionsSecondary.app, isA<FirebaseApp>());
        expect(functionsSecondary.app.name, secondaryApp!.name);
      });

      test('accepts a secondary FirebaseApp instance and custom region',
          () async {
        final functionsSecondary = FirebaseFunctions.instanceFor(
            app: secondaryApp, region: 'europe-west1');
        expect(functionsSecondary.app, isA<FirebaseApp>());
        expect(functionsSecondary.app.name, secondaryApp!.name);
        expect(functionsSecondary.delegate.region, equals('europe-west1'));
      });

      test('accepts a custom region for the default app', () async {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        expect(functions.app, isA<FirebaseApp>());
        expect(functions.app.name, defaultFirebaseAppName);
        expect(functions.delegate.region, equals('europe-west1'));
      });

      test('caches instances by FirebaseApp and region', () async {
        // Instances using the same region and FirebaseApp should be identical.
        final functions1 =
            FirebaseFunctions.instanceFor(region: 'europe-west1');
        final functions2 =
            FirebaseFunctions.instanceFor(region: 'europe-west1');
        expect(functions1, same(functions2));

        // Instances using the same region but a different FirebaseApp should not be identical.
        final functions3 = FirebaseFunctions.instanceFor(
            app: secondaryApp, region: 'europe-west1');
        expect(functions1, isNot(same(functions3)));

        // Instances using the same FirebaseApp but a different region should not be identical.
        final functions4 =
            FirebaseFunctions.instanceFor(region: 'europe-west2');
        expect(functions1, isNot(same(functions4)));
      });
    });

    group('.useEmulator()', () {
      test('passes emulator "origin" through to the delegate', () {
        // Check null by default.
        expect(FirebaseFunctions.instance.httpsCallable('test').delegate.origin,
            isNull);
        // Set the origin for the default FirebaseFunctions instance.
        FirebaseFunctions.instance.useFunctionsEmulator('0.0.0.0', 5000);

        expect(FirebaseFunctions.instance.httpsCallable('test').delegate.origin,
            equals('http://0.0.0.0:5000'));
      });

      test('"origin" is only set for the specific FirebaseFunctions instance',
          () {
        FirebaseFunctions.instance.useFunctionsEmulator('0.0.0.0', 5000);
        // Origin on the default FirebaseFunctions instance should be set.
        expect(FirebaseFunctions.instance.httpsCallable('test').delegate.origin,
            equals('http://0.0.0.0:5000'));
        // Origin on a secondary FirebaseFunctions instance should remain unset/null.
        expect(
            FirebaseFunctions.instanceFor(region: 'europe-west1')
                .httpsCallable('test')
                .delegate
                .origin,
            isNull);
      });

      test('handles "localhost" and "127.0.0.1" origin only for Android', () {
        const testLocalhostOrigins = [
          '127.0.0.1',
          'localhost',
        ];

        for (final platform in TargetPlatform.values) {
          debugDefaultTargetPlatformOverride = platform;

          for (final testOrigin in testLocalhostOrigins) {
            final expectedOrigin = platform == TargetPlatform.android
                ? 'http://10.0.2.2:5000'
                : 'http://$testOrigin:5000';

            FirebaseFunctions.instance.useFunctionsEmulator(testOrigin, 5000);
            // Origin on the default FirebaseFunctions instance should be set.
            expect(
                FirebaseFunctions.instance
                    .httpsCallable('test')
                    .delegate
                    .origin,
                equals(expectedOrigin));
          }
        }
      });
    });

    group('.httpsCallable()', () {
      test('throws if "name" is an empty string', () {
        expect(() {
          FirebaseFunctions.instance.httpsCallable('');
        }, throwsA(isA<AssertionError>()));
      });

      test('passes "name" through to delegate', () {
        expect(FirebaseFunctions.instance.httpsCallable('foo').delegate.name,
            equals('foo'));
      });

      test('provides default "options" if none provided', () {
        expect(FirebaseFunctions.instance.httpsCallable('foo').delegate.options,
            isNotNull);
      });

      test('passes custom "options" through to the delegate', () {
        final delegate = FirebaseFunctions.instance
            .httpsCallable('foo',
                options: HttpsCallableOptions(
                    timeout: const Duration(seconds: 1337)))
            .delegate;
        expect(delegate.options, isNotNull);
        expect(delegate.options.timeout, isA<Duration>());
        expect(delegate.options.timeout.inSeconds, equals(1337));
      });
    });
  });

  group('HttpsCallable', () {
    late HttpsCallable httpsCallable;
    setUpAll(() async {
      final app = await Firebase.initializeApp(
          name: 'an app', options: firebaseOptions);
      final firebaseFunctions = FirebaseFunctions.instanceFor(app: app);
      final delegate = firebaseFunctions.delegate as FirebaseFunctionsDesktop;
      delegate.dartFunctions.setApiClient(
          MockClient((http.Request request) async => http.Response(
                request.body,
                200,
                headers: {'content-type': 'application/json'},
              )));

      httpsCallable = firebaseFunctions.httpsCallable('foo');
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
}
