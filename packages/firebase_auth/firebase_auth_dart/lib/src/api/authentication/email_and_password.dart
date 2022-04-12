part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyPassword`: sign in a user with an email and password.
/// - `signupNewUser`: create a new email and password user.
/// - `setAccountInfo`: change user account info based on request parameters.
/// - `getOobConfirmationCode`: send an email verification for the current user
/// or send a password reset email.
@internal
class EmailAndPasswordAuth {
  // ignore: public_member_api_docs
  const EmailAndPasswordAuth(this._api);

  final API _api;

  /// TODO: write endpoint details
  Future<VerifyPasswordResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final _response = await _api.identityToolkit.verifyPassword(
      IdentitytoolkitRelyingpartyVerifyPasswordRequest(
        returnSecureToken: true,
        password: password,
        email: email,
      ),
    );

    return _response;
  }

  /// TODO: write endpoint details
  Future<SignupNewUserResponse> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final _response = await _api.identityToolkit.signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest(
        email: email,
        password: password,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<SetAccountInfoResponse> linkWithEmail(
    String idToken, {
    required EmailAuthCredential credential,
  }) async {
    return _api.identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        email: credential.email,
        password: credential.password,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<String?> sendVerificationEmail(String idToken) async {
    final _response = await _api.identityToolkit.getOobConfirmationCode(
      Relyingparty(requestType: 'VERIFY_EMAIL', idToken: idToken),
    );

    return _response.email;
  }

  /// TODO: write endpoint details
  Future<String> sendPasswordResetEmail(
    String email, {
    String? continueUrl,
  }) async {
    final _response = await _api.identityToolkit.getOobConfirmationCode(
      Relyingparty(
        email: email,
        requestType: 'PASSWORD_RESET',
        continueUrl: continueUrl,
      ),
    );

    return _response.email!;
  }

  /// TODO: write endpoint details
  Future<GetOobConfirmationCodeResponse> sendSignInLinkToEmail(
    String email,
    String? continueUrl,
  ) async {
    return _api.identityToolkit.getOobConfirmationCode(
      Relyingparty(
        email: email,
        requestType: 'EMAIL_SIGNIN',
        // have to be sent, otherwise the user won't be redirected to the app.
        continueUrl: continueUrl,
      ),
    );
  }
}
