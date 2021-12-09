// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  final mock = MockFirebaseCoreDelegate();

  const testOptions = FirebaseOptions(
    apiKey: 'apiKey',
    appId: 'appId',
    messagingSenderId: 'messagingSenderId',
    projectId: 'projectId',
  );

  const testAppName = 'testApp';
  group('$Firebase', () {
    setUp(() async {
      clearInteractions(mock);
      Firebase.delegatePackingProperty = mock;

      final fakeApp = FakeFirebaseApp(name: testAppName, options: testOptions);
      final fakeDefaultApp = FakeFirebaseApp(options: testOptions);

      when(mock.apps).thenReturn([fakeApp]);
      when(mock.app()).thenReturn(fakeDefaultApp);
      when(mock.app(testAppName)).thenReturn(fakeApp);
      when(mock.initializeApp(name: testAppName, options: testOptions))
          .thenAnswer((_) {
        return Future.value(fakeApp);
      });
      when(mock.initializeApp(options: testOptions)).thenAnswer((_) {
        return Future.value(fakeDefaultApp);
      });
    });

    test('.apps', () {
      final apps = Firebase.apps;
      verify(mock.apps);
      expect(apps[0], Firebase.app(testAppName));
    });

    test('.app()', () {
      final app = Firebase.app(testAppName);
      verify(mock.app(testAppName));

      expect(app.name, testAppName);
      expect(app.options, testOptions);
    });

    test('.initializeApp() default', () async {
      final initializedApp = await Firebase.initializeApp(
        options: testOptions,
      );
      final app = Firebase.app();

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(options: testOptions),
        mock.app(),
      ]);
    });

    test('.initializeApp() secondary', () async {
      final initializedApp = await Firebase.initializeApp(
        name: testAppName,
        options: testOptions,
      );
      final app = Firebase.app(testAppName);

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(name: testAppName, options: testOptions),
        mock.app(testAppName),
      ]);
    });
  });
}

// ignore: avoid_implementing_value_types
class MockFirebaseCoreDelegate extends Mock implements FirebaseCoreDelegate {
  @override
  FirebaseApp app([String name = defaultFirebaseAppName]) {
    return super.noSuchMethod(
      Invocation.method(#app, [name]),
      returnValue: FakeFirebaseApp(),
      returnValueForMissingStub: FakeFirebaseApp(),
    );
  }

  @override
  Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #initializeApp,
        const [],
        {
          #name: name,
          #options: options,
        },
      ),
      returnValue: Future.value(FakeFirebaseApp()),
      returnValueForMissingStub: Future.value(FakeFirebaseApp()),
    );
  }

  @override
  List<FirebaseApp> get apps {
    return super.noSuchMethod(
      Invocation.getter(#apps),
      returnValue: <FirebaseApp>[],
      returnValueForMissingStub: <FirebaseApp>[],
    );
  }
}

// ignore: avoid_implementing_value_types
class FakeFirebaseApp extends Fake implements FirebaseApp {
  FakeFirebaseApp({String? name, FirebaseOptions? options}) {
    if (name != null) {
      this.name = name;
    }
    if (options != null) {
      this.options = options;
    }
  }

  @override
  late String name;
  @override
  late FirebaseOptions options;
}
