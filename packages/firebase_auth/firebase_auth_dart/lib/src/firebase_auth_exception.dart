// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_core_dart/firebase_core_dart.dart';

/// All possible error codes returned from Identity Platform REST API.
const Map error = {
  'EMAIL_NOT_FOUND':
      'There is no user record corresponding to this identifier. The user may have been deleted.',
  'WRONG_PASSWORD':
      'The password is invalid or the user does not have a password.',
  'USER_DISABLED': 'The user account has been disabled by an administrator.',
  'EMAIL_ALREADY_IN_USE':
      'The email address is already in use by another account.',
  'OPERATION_NOT_ALLOWED':
      'Password sign-in feature is disabled for this project.',
  'TOO_MANY_ATTEMPTS_TRY_LATER':
      'This device is blocked due to unusual activity.',
  'INVALID_EMAIL': 'The email address is badly formatted.',
  'INVALID_IDENTIFIER':
      'The identifier provided to `createAuthUri` is invalid.',
  'NO_CURRENT_USER': 'No user currently signed in.',
  'INVALID_ID_TOKEN':
      "The user's credential is no longer valid. The user must sign in or reauthenticate.",
  'USER_NOT_FOUND':
      'There is no user record corresponding to this identifier. The user may have been deleted.',
  'TOKEN_EXPIRED':
      "The user's credential is no longer valid. The user must sign in again.",
  'INVALID_REFRESH_TOKEN':
      "The user's credential is no longer valid. The user must sign in again.",
  'INVALID_GRANT_TYPE':
      "The user's credential is no longer valid. The user must sign in again.",
  'MISSING_REFRESH_TOKEN':
      "The user's credential is no longer valid. The user must sign in again.",
  'INVALID_IDP_RESPONSE':
      "The user's credential is no longer valid. The user must sign in again.",
  'EXPIRED_OOB_CODE': 'The action code has expired.',
  'INVALID_OOB_CODE':
      'The action code is invalid. This can happen if the code is malformed, expired, or has already been used.',
  'WEAK_PASSWORD': 'Password should be at least 6 characters.',
  'CREDENTIAL_TOO_OLD_LOGIN_AGAIN':
      "The user's credential is no longer valid. The user must sign in again.",
  'FEDERATED_USER_ID_ALREADY_LINKED':
      'This credential is already associated with a different user account.',
  'INVALID_PHONE_NUMBER': 'The provided phone number is not valid.',
  'INVALID_CODE': 'The provided code is not valid.',
  'UKNOWN': 'Uknown error happened.',
  'CAPTCHA_CHECK_FAILED':
      'The reCAPTCHA response token was invalid, expired, or is called from a non-whitelisted domain.',
  'NEED_CONFIRMATION': 'Account exists with different credential.',
  'VERIFICATION_CANCELED':
      'Recaptcha verification process was canceled by user.',
  'INVALID_VERIFICATION_ID':
      'The verification ID used to create the phone auth credential is invalid.',
  'USER_MISMATCH':
      'The supplied credentials do not correspond to the previously signed in user.',
  'NO_SUCH_PROVIDER':
      'User was not linked to an account with the given provider.',
};

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
