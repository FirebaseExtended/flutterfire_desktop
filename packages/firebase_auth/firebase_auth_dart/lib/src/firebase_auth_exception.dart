// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_core_dart/firebase_core_dart.dart';

import 'api/errors.dart';

/// Wrap the errors from the Identity Platform REST API, usually of type `DetailedApiRequestError`
/// in a in a Firebase-friendly format to users.
class FirebaseAuthException extends FirebaseException implements Exception {
  // ignore: public_member_api_docs
  FirebaseAuthException({String code = 'UKNOWN', String? message})
      : super(
          plugin: 'firebase_auth',
          code: _getCode(code),
          message: error[_castCode(code)] ?? message,
        );

  static String _castCode(String code) {
    var _code = code;

    // To be consistent with FlutterFire.
    switch (_code) {
      case 'INVALID_OOB_CODE':
        _code = 'INVALID_ACTION_CODE';
        break;
      case 'EMAIL_EXISTS':
        _code = 'EMAIL_ALREADY_IN_USE';
        break;
      case 'INVALID_IDENTIFIER':
        _code = 'INVALID_EMAIL';
        break;
      case 'EMAIL_NOT_FOUND':
        _code = 'USER_NOT_FOUND';
        break;
      case 'INVALID_PASSWORD':
        _code = 'WRONG_PASSWORD';
        break;
      case 'INVALID_SESSION_INFO':
        _code = 'INVALID_VERIFICATION_ID';
        break;
    }

    return _code;
  }

  /// Map to error code that matches the rest of FlutterFire plugins.
  static String _getCode(String code) {
    return _castCode(code)
        .toLowerCase()
        .replaceAll('error_', '')
        .replaceAll('_', '-');
  }
}
