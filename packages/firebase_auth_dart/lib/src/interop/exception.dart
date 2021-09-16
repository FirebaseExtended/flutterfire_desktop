/// All possible error codes returned from Identity Platform REST API.
class ErrorCode {
  /// Thrown if there is no registered user corresponding to this email.
  static const emailNotFound = 'EMAIL_NOT_FOUND';

  /// Thrown if the password of this user is invalid.
  static const invalidPassword = 'INVALID_PASSWORD';

  /// Thrown if the user exists but is disabled.
  static const userDisabled = 'USER_DISABLED';
}

/// And exception wrapping error codes from the IP API.
class IPException implements Exception {
  // ignore: public_member_api_docs
  IPException([this.message = '', this.code]);

  /// Constrict and IPException based on the returned error code.
  factory IPException.fromErrorCode(String? code) {
    switch (code) {
      case ErrorCode.emailNotFound:
        return IPException('The user is not found.', code);
      case ErrorCode.invalidPassword:
        return IPException('The user password is incorrect.', code);
      case ErrorCode.userDisabled:
        return IPException('The user is disabled.', code);
      default:
        return IPException('Unknown error happened.', 'UNKNOWN');
    }
  }

  /// A message describing the IP error.
  final String message;

  // ignore: public_member_api_docs
  final String? code;

  @override
  String toString() => message;
}
