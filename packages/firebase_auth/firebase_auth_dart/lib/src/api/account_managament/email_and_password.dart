part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `setAccountInfo`: change a user's email or password.
/// - `resetPassword`: apply a password reset change.
@internal
class EmailAndPasswordAccount extends APIDelegate {
  // ignore: public_member_api_docs
  const EmailAndPasswordAccount(API api) : super(api);

  /// Change a user's email.
  ///
  /// Common error codes:
  /// - `EMAIL_EXISTS`: The email address is already in use by another account.
  /// - `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  Future<SetAccountInfoResponse> updateEmail(
    String newEmail,
    String idToken,
    String uid,
  ) async {
    try {
      final response = await api.identityToolkit.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest(
          email: newEmail,
          idToken: idToken,
          localId: uid,
        ),
      );

      return response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Change a user's password.
  ///
  /// Common error codes:
  /// - `INVALID_ID_TOKEN`:The user's credential is no longer valid. The user must sign in again.
  /// - `WEAK_PASSWORD`: The password must be 6 characters long or more.
  Future<SetAccountInfoResponse> updatePassword(
    String idToken, {
    String? newPassword,
  }) async {
    try {
      final response = await api.identityToolkit.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest(
          idToken: idToken,
          password: newPassword,
        ),
      );

      return response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Apply a password reset change.
  ///
  /// Common error codes:
  /// - `OPERATION_NOT_ALLOWED`: Password sign-in is disabled for this project.
  /// - `EXPIRED_OOB_CODE`: The action code has expired.
  /// - `INVALID_OOB_CODE`: The action code is invalid. This can happen if the
  /// code is malformed, expired, or has already been used.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  Future<String> resetPassword(String? code, String? newPassword) async {
    try {
      final response = await api.identityToolkit.resetPassword(
        IdentitytoolkitRelyingpartyResetPasswordRequest(
          newPassword: newPassword,
          oobCode: code,
        ),
      );

      return response.email!;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
