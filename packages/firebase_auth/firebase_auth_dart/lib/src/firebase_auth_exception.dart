part of firebase_auth_dart;

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
}

/// And exception wrapping error codes from the IP API.
class AuthException implements Exception {
  // ignore: public_member_api_docs
  AuthException([this.message = '', this.code]);

  /// Constrict and IPException based on the returned error code.
  factory AuthException.fromErrorCode(String? code) {
    switch (code) {
      case ErrorCode.emailNotFound:
        return AuthException(
            'There is no user record corresponding to this identifier.'
            ' The user may have been deleted.',
            code);
      case ErrorCode.invalidPassword:
        return AuthException(
            'The password is invalid or the user does not have a password.',
            code);
      case ErrorCode.userDisabled:
        return AuthException(
            'The user account has been disabled by an administrator.', code);
      case ErrorCode.emailExists:
        return AuthException(
            'The email address is already in use by another account.', code);
      case ErrorCode.operationNotAllowed:
        return AuthException(
            'Password sign-in is disabled for this project.', code);
      case ErrorCode.tooManyAttempts:
        return AuthException(
            'We have blocked all requests from this device'
            ' due to unusual activity. Try again later.',
            code);
      case ErrorCode.invalidEmail:
        return AuthException('Email address is badly formatted.', code);
      case ErrorCode.invalidIdentifier:
        return AuthException('Invalid identifier, either empty or null.', code);
      default:
        return AuthException('Unknown error happened.', 'UNKNOWN');
    }
  }

  /// A message describing the IP error.
  final String message;

  // ignore: public_member_api_docs
  final String? code;

  @override
  String toString() => message;
}
