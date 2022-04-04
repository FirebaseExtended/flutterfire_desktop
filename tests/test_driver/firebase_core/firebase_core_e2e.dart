// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'package:drive/drive.dart';

import '../firebase_options.dart';

void setupTests() {
  group('firebase_core', () {
    String testAppName = 'testApp';

    setUpAll(() async {
      await Firebase.initializeApp(
        name: testAppName,
        options: options,
      );
    });

    test('Firebase.apps', () async {
      List<FirebaseApp> apps = Firebase.apps;
      expect(apps.length, 1);
      expect(apps[0].name, testAppName);
      expect(apps[0].options, options);
    });

    test('Firebase.app()', () async {
      FirebaseApp app = Firebase.app(testAppName);

      expect(app.name, testAppName);
      expect(app.options, options);
    });

    test('Firebase.app() Exception', () async {
      expect(
        () => Firebase.app('NoApp'),
        throwsA(noAppExists('NoApp')),
      );
    });

    test('FirebaseApp.delete()', () async {
      await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: options,
      );

      expect(Firebase.apps.length, 2);

      FirebaseApp app = Firebase.app('SecondaryApp');

      await app.delete();

      expect(Firebase.apps.length, 1);
    });

    test('FirebaseApp.setAutomaticDataCollectionEnabled()', () async {
      FirebaseApp app = Firebase.app(testAppName);
      bool enabled = app.isAutomaticDataCollectionEnabled;

      await app.setAutomaticDataCollectionEnabled(!enabled);

      expect(app.isAutomaticDataCollectionEnabled, !enabled);
    });

    test('FirebaseApp.setAutomaticResourceManagementEnabled()', () async {
      FirebaseApp app = Firebase.app(testAppName);

      await app.setAutomaticResourceManagementEnabled(true);
    });
  });
}
