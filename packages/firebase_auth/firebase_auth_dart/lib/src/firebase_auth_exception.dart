// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of flutterfire_auth_dart;

/// All possible error codes returned from Identity Platform REST API.
class ErrorCode {
  /// Thrown if there is no registered user corresponding to this email.
  static const emailNotFound = 'EMAIL_NOT_FOUND';

  /// Thrown if the password of this user is invalid.
  static const invalidPassword = 'INVALID_PASSWORD';

  /// Thrown if the user exists but is disabled.
  static const userDisabled = 'USER_DISABLED';

  /// Thrown if the user is trying to sign up with an existed email.
  static const emailExists = 'EMAIL_EXISTS';

  /// Thrown if password sign-in feature is disabled for this project.
  static const operationNotAllowed = 'OPERATION_NOT_ALLOWED';

  /// Thrown if this device is blocked due to unusual activity.
  static const tooManyAttempts = 'TOO_MANY_ATTEMPTS_TRY_LATER';

  /// Thrown if the email address is badly formatted.
  static const invalidEmail = 'INVALID_EMAIL';

  /// Thrown if the identifier provided to `createAuthUri` is invalid.
  static const invalidIdentifier = 'INVALID_IDENTIFIER';

  /// Thrown when the operation requires a user to be signed in.
  static const userNotSignedIn = 'NOT_SIGNED_IN';

  /// Thrown when the user's credential is no longer valid. The user must sign in or reauthenticate.
  static const invalidIdToken = 'INVALID_ID_TOKEN';

  /// Thrown when the user's credential is no longer valid. The user must sign in or reauthenticate.
  static const userNotFound = 'USER_NOT_FOUND';
}

/// Exception wrapping error codes from the Identity Platform REST API, usually of type [idp.DetailedApiRequestError].
class FirebaseAuthException extends FirebaseException implements Exception {
  // ignore: public_member_api_docs
  FirebaseAuthException({required String code, String message = ''})
      : super(plugin: 'firebase_auth', code: code, message: message);

  /// Construct an exception based on the returned error code.
  factory FirebaseAuthException.fromErrorCode(String code, {String? message}) {
    switch (code) {
      case ErrorCode.emailNotFound:
        return FirebaseAuthException(
          message: 'There is no user record corresponding to this identifier.'
              ' The user may have been deleted.',
          code: code,
        );
      case ErrorCode.invalidPassword:
        return FirebaseAuthException(
          message:
              'The password is invalid or the user does not have a password.',
          code: code,
        );
      case ErrorCode.userDisabled:
        return FirebaseAuthException(
          message: 'The user account has been disabled by an administrator.',
          code: code,
        );
      case ErrorCode.emailExists:
        return FirebaseAuthException(
          message: 'The email address is already in use by another account.',
          code: code,
        );
      case ErrorCode.operationNotAllowed:
        return FirebaseAuthException(
          message: 'Password sign-in is disabled for this project.',
          code: code,
        );
      case ErrorCode.tooManyAttempts:
        return FirebaseAuthException(
          message: 'We have blocked all requests from this device'
              ' due to unusual activity. Try again later.',
          code: code,
        );
      case ErrorCode.invalidEmail:
        return FirebaseAuthException(
          message: 'Email address is badly formatted.',
          code: code,
        );
      case ErrorCode.invalidIdentifier:
        return FirebaseAuthException(
          message: 'Invalid identifier, either empty or null.',
          code: code,
        );
      case ErrorCode.userNotSignedIn:
        return FirebaseAuthException(
          message: 'There is no user currently signed in.',
          code: code,
        );
      case ErrorCode.invalidIdToken:
        return FirebaseAuthException(
          message:
              'The user is credential is no longer valid. The user must sign in again.',
          code: code,
        );
      case ErrorCode.userNotFound:
        return FirebaseAuthException(
          message:
              'There is no user record corresponding to this identifier. The user may have been deleted.',
          code: code,
        );
      default:
        return FirebaseAuthException(
          message: message ?? 'Unknown error happened.',
          code: 'UNKNOWN',
        );
    }
  }
}
