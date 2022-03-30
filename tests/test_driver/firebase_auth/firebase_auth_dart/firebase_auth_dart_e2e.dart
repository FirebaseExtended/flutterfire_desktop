// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';

import 'package:drive/drive.dart';

import 'test_utils.dart';
import 'firebase_auth_instance_e2e.dart' as instance_tests;
import 'firebase_auth_user_e2e.dart' as user_tests;

void setupTests() {
  group('firebase_auth', () {
    setUpAll(() async {
      const options = FirebaseOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        authDomain: 'react-native-firebase-testing.firebaseapp.com',
        databaseURL: 'https://react-native-firebase-testing.firebaseio.com',
        projectId: 'react-native-firebase-testing',
        storageBucket: 'react-native-firebase-testing.appspot.com',
        messagingSenderId: '448618578101',
        appId: '1:448618578101:web:0b650370bb29e29cac3efc',
        measurementId: 'G-F79DJ0VFGS',
      );

      await Firebase.initializeApp(options: options);

      if (useEmulator) {
        await FirebaseAuth.instance.useAuthEmulator();
      }
    });

    setUp(() async {
      // Reset users on emulator.
      await emulatorClearAllUsers();
      // Create a generic testing user account.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        testEmail,
        testPassword,
      );
      // Create a disabled user account.
      // final disabledUserCredential =
      //     await FirebaseAuth.instance.createUserWithEmailAndPassword(
      // testDisabledEmail,
      //  testPassword,
      // );
      // await emulatorDisableUser(disabledUserCredential.user!.uid);
      // await ensureSignedOut();
    });

    instance_tests.setupTests();
    user_tests.setupTests();
  });
}
