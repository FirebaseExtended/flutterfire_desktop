// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';

import 'package:drive/drive.dart';

import '../../firebase_options_dart.dart';
import 'test_utils.dart';
import 'firebase_auth_instance_e2e.dart' as instance_tests;
import 'firebase_auth_user_e2e.dart' as user_tests;

void setupTests() {
  group('firebase_auth', () {
    setUpAll(() async {
      await Firebase.initializeApp(options: optionsDart);

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
      final disabledUserCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        testDisabledEmail,
        testPassword,
      );

      await emulatorDisableUser(disabledUserCredential.user!.uid);
      await ensureSignedOut();
    });

    instance_tests.setupTests();
    user_tests.setupTests();
  });
}
