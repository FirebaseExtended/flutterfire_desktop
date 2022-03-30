// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:drive/drive.dart' as drive;
import 'firebase_auth/firebase_auth_e2e.dart' as firebase_auth;
import 'firebase_core/firebase_core_e2e.dart' as firebase_core;
import 'firebase_functions/firebase_functions_e2e.dart' as firebase_functions;

void setupTests() {
  // Core first.
  firebase_core.setupTests();
  // All other tests.
  firebase_auth.setupTests();
  firebase_functions.setupTests();
}

void main() => drive.main(setupTests);
