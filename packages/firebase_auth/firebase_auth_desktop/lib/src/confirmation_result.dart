// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import '../src/utils/desktop_utils.dart';
import 'firebase_auth_user_credential.dart';

/// The desktop delegate implementation for [ConfirmationResultPlatform].
class ConfirmationResultDesktop extends ConfirmationResultPlatform {
  /// Creates a new [ConfirmationResultDesktop] instance.
  ConfirmationResultDesktop(this._auth, this._result)
      : super(_result.verificationId);
  final auth_dart.ConfirmationResult _result;

  final FirebaseAuthPlatform _auth;

  @override
  Future<UserCredentialPlatform> confirm(String verificationCode) async {
    try {
      return UserCredential(_auth, await _result.confirm(verificationCode));
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }
}
