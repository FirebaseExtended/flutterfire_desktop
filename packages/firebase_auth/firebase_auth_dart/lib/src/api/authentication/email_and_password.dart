part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyPassword`: sign in a user with an email and password.
/// - `signupNewUser`: create a new email and password user.
/// - `setAccountInfo`: change user account info based on request parameters.
/// - `getOobConfirmationCode`: send an email verification for the current user
/// or send a password reset email.
@internal
class EmailAndPasswordAuth extends APIDelegate {
  // ignore: public_member_api_docs
  const EmailAndPasswordAuth(API api) : super(api);

  /// Sign in a user with an email and password.
  ///
  /// Common error codes:
  /// - `EMAIL_NOT_FOUND`: There is no user record corresponding to this identifier.
  /// The user may have been deleted.
  /// - `INVALID_PASSWORD`: The password is invalid or the user does not have a password.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  Future<VerifyPasswordResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final _response = await api.identityToolkit.verifyPassword(
        IdentitytoolkitRelyingpartyVerifyPasswordRequest(
          returnSecureToken: true,
          password: password,
          email: email,
        ),
      );

      return _response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Create a new email and password user.
  ///
  /// Common error codes:
  /// - `EMAIL_EXISTS`: The email address is already in use by another account.
  /// - `OPERATION_NOT_ALLOWED`: Password sign-in is disabled for this project.
  /// - `TOO_MANY_ATTEMPTS_TRY_LATER`: We have blocked all requests from this
  /// device due to unusual activity. Try again later.
  Future<SignupNewUserResponse> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final _response = await api.identityToolkit.signupNewUser(
        IdentitytoolkitRelyingpartySignupNewUserRequest(
          email: email,
          password: password,
        ),
      );
      return _response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Link an email/password to a current user.
  ///
  /// Common error codes:
  /// - `CREDENTIAL_TOO_OLD_LOGIN_AGAIN`: The user's credential is no longer valid. The user must sign in again.
  /// - `TOKEN_EXPIRED`: The user's credential is no longer valid. The user must sign in again.
  /// - `INVALID_ID_TOKEN`:The user's credential is no longer valid. The user must sign in again.
  /// - `WEAK_PASSWORD`: The password must be 6 characters long or more.
  Future<SetAccountInfoResponse> linkWithEmail(
    String idToken, {
    required EmailAuthCredential credential,
  }) async {
    try {
      final response = await api.identityToolkit.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest(
          idToken: idToken,
          email: credential.email,
          password: credential.password,
        ),
      );

      return response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Send an email verification for the current user.
  ///
  /// Common error codes:
  /// - `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  /// - `USER_NOT_FOUND`: There is no user record corresponding to this identifier.
  /// The user may have been deleted.
  Future<String?> sendVerificationEmail(String idToken) async {
    try {
      final _response = await api.identityToolkit.getOobConfirmationCode(
        Relyingparty(requestType: 'VERIFY_EMAIL', idToken: idToken),
      );

      return _response.email;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Send a password reset email.
  ///
  /// Common error codes:
  /// - `EMAIL_NOT_FOUND`: There is no user record corresponding to this identifier.
  /// The user may have been deleted.
  Future<String> sendPasswordResetEmail(
    String email, {
    String? continueUrl,
  }) async {
    try {
      final _response = await api.identityToolkit.getOobConfirmationCode(
        Relyingparty(
          email: email,
          requestType: 'PASSWORD_RESET',
          continueUrl: continueUrl,
        ),
      );

      return _response.email!;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
