part of firebase_auth_dart;

/// All possible error codes returned from Identity Platform REST API [idp].
Map error = {
  'EMAIL_NOT_FOUND': 'There is no registered user corresponding to this email.',
  'INVALID_PASSWORD': 'The password of this user is invalid.',
  'USER_DISABLED': 'The user exists but is disabled.',
  'EMAIL_EXISTS': 'The user is trying to sign up with an existed email.',
  'OPERATION_NOT_ALLOWED':
      'Password sign-in feature is disabled for this project.',
  'TOO_MANY_ATTEMPTS_TRY_LATER':
      'This device is blocked due to unusual activity.',
  'INVALID_EMAIL': 'The email address is badly formatted.',
  'INVALID_IDENTIFIER':
      'The identifier provided to `createAuthUri` is invalid.',
  'NOT_SIGNED_IN': 'The operation requires a user to be signed in.',
  'INVALID_ID_TOKEN':
      "The user's credential is no longer valid. The user must sign in or reauthenticate.",
  'USER_NOT_FOUND':
      "The user's credential is no longer valid. The user must sign in or reauthenticate.",
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
  'WEAK_PASSWORD': 'The password must be 6 characters long or more.',
  'CREDENTIAL_TOO_OLD_LOGIN_AGAIN':
      "The user's credential is no longer valid. The user must sign in again.",
  'FEDERATED_USER_ID_ALREADY_LINKED':
      'This credential is already associated with a different user account.',
  'UKNOWN': 'Uknown error happened.',
};

/// Wrap the errors from the Identity Platform REST API, usually of type [idp.DetailedApiRequestError]
/// in a in a Firebase-friendly format to users.
class FirebaseAuthException extends FirebaseException implements Exception {
  // ignore: public_member_api_docs
  FirebaseAuthException({String code = 'UKNOWN', String? message})
      : super(
          plugin: 'firebase_auth',
          code: _getCode(code),
          message: error[code] ?? message,
        );

  /// Map to error code that matches the rest of FlutterFire plugins.
  static String _getCode(String code) {
    return code.toLowerCase().replaceAll('error_', '').replaceAll('_', '-');
  }
}
