// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_remote_config_dart/firebase_remote_config_dart.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:storagebox/storagebox.dart';
import 'package:test/test.dart';
// ignore: import_of_legacy_library_into_null_safe

FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
    );
void main() {
  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
      ),
    );
  });

  setUp(() async {});

  group('FirebaseRemoteConfig', () {
    group('.instance', () {
      test('uses the default FirebaseApp instance', () {
        expect(FirebaseRemoteConfig.instance.app, isA<FirebaseApp>());
        expect(
          FirebaseRemoteConfig.instance.app.name,
          equals(defaultFirebaseAppName),
        );
      });

      test('uses the default firebase namespace', () {
        expect(FirebaseRemoteConfig.instance.namespace, equals('firebase'));
      });
    });

    group('.instanceFor()', () {
      late FirebaseApp secondaryApp;

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
        final remoteConfigSecondary =
            FirebaseRemoteConfig.instanceFor(app: secondaryApp);
        expect(remoteConfigSecondary.app, isA<FirebaseApp>());
        expect(remoteConfigSecondary.app.name, secondaryApp.name);
      });

      test('accepts a secondary FirebaseApp instance and custom namespace',
          () async {
        final remoteConfigSecondary = FirebaseRemoteConfig.instanceFor(
          app: secondaryApp,
          namespace: 'firebase2',
        );
        expect(remoteConfigSecondary.app, isA<FirebaseApp>());
        expect(remoteConfigSecondary.app.name, secondaryApp.name);
        expect(remoteConfigSecondary.namespace, equals('firebase2'));
      });

      test('accepts a custom namespace for the default app', () async {
        final remoteConfig =
            FirebaseRemoteConfig.instanceFor(namespace: 'firebase2');
        expect(remoteConfig.app, isA<FirebaseApp>());
        expect(remoteConfig.app.name, defaultFirebaseAppName);
        expect(remoteConfig.namespace, equals('firebase2'));
      });

      test('caches instances by FirebaseApp and namespace', () async {
        // Instances using the same namespace and FirebaseApp should be identical.
        final remoteConfig1 =
            FirebaseRemoteConfig.instanceFor(namespace: 'firebase2');
        final remoteConfig2 =
            FirebaseRemoteConfig.instanceFor(namespace: 'firebase2');
        expect(remoteConfig1, same(remoteConfig2));

        // Instances using the same namespace but a different FirebaseApp should not be identical.
        final remoteConfig3 = FirebaseRemoteConfig.instanceFor(
          app: secondaryApp,
          namespace: 'firebase2',
        );
        expect(remoteConfig1, isNot(same(remoteConfig3)));

        // Instances using the same FirebaseApp but a different namespace should not be identical.
        final remoteConfig4 =
            FirebaseRemoteConfig.instanceFor(namespace: 'firebase1');
        expect(remoteConfig1, isNot(same(remoteConfig4)));
      });
    });

    group('Api', () {
      late final FirebaseRemoteConfig rc;
      setUpAll(() {
        rc = FirebaseRemoteConfig.instance;

        StorageBox('firebase_remote_config').clear();
      });
      test('Fetch updates time, status', () async {
        rc.api = FakeConfigClient(
          rc.app.options.projectId,
          'firebase',
          rc.app.options.apiKey,
          rc.app.options.appId,
          rc.storage,
          rc.storageCache,
        );
        final before = rc.lastFetchTime;
        expect(before, equals(DateTime.fromMillisecondsSinceEpoch(0)));
        expect(rc.lastFetchStatus, equals(RemoteConfigFetchStatus.noFetchYet));

        await rc.fetch();

        expect(rc.lastFetchStatus, equals(RemoteConfigFetchStatus.success));
        final after = rc.lastFetchTime;
        expect(before, isNot(after));
        expect(() => rc.getValue('key'), throwsA(isA<AssertionError>()));
        await rc.ensureInitialized();
        expect(rc.getAll(), isEmpty);
        expect(rc.storage.getLastSuccessfulFetchResponse(), isNotNull);
      });

      test('Activate updates config', () async {
        expect(rc.getAll(), isEmpty);
        await rc.activate();
        expect(rc.getAll(), isNotEmpty);
        expect(rc.getAll().length, equals(2));
        expect(
          rc.getAll().values.every((v) => v.source == ValueSource.valueRemote),
          true,
        );
      });

      test('Default config values', () {
        rc.setDefaults({
          'string_key': 'default',
          'number_key': 42,
          'bool_key': true,
          'foo': 'new foo'
        });

        expect(rc.getAll().length, 5);
        expect(rc.getString('bar'), equals('bar'));
        expect(rc.getString('foo'), equals('real foo'));
        expect(rc.getString('string_key'), equals('default'));
        expect(rc.getInt('number_key'), equals(42));
        expect(rc.getBool('bool_key'), equals(true));
        expect(rc.getValue('foo').source, equals(ValueSource.valueRemote));
        expect(
          rc
              .getAll()
              .values
              .where((v) => v.source == ValueSource.valueRemote)
              .length,
          equals(2),
        );
        expect(
          rc
              .getAll()
              .values
              .where((v) => v.source == ValueSource.valueDefault)
              .length,
          equals(3),
        );
        rc.setDefaults({});
        expect(rc.getAll().length, 2);
      });

      test('InitialValues overrides active config', () {
        rc.setInitialValues(
          remoteConfigValues: {
            'fetchTimeout': 10,
            'minimumFetchInterval': 200,
            'lastFetchTime': DateTime.now().millisecondsSinceEpoch,
            'lastFetchStatus': 'success',
            'parameters': {
              'bar': {'source': 'remote', 'value': 'new bar'},
            }
          },
        );
        expect(rc.getAll().length, equals(1));
      });
    });
  });
}

class FakeConfigClient extends RemoteConfigApiClient {
  FakeConfigClient(
    String projectId,
    String namespace,
    String apiKey,
    String appId,
    storage,
    storageCache,
  ) : super(projectId, namespace, apiKey, appId, storage, storageCache);
  @override
  Client get httpClient => MockClient(
        (request) => Future<Response>.value(
          Response(
            '''
{
  "parameters": {
    "bar": {"defaultValue": {"value": "bar"}},
    "foo": {"defaultValue": {"value": "real foo"}}
  }
}''',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
}
