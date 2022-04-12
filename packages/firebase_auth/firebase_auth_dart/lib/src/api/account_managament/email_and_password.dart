part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `setAccountInfo`: change a user's email or password.
/// - `resetPassword`: apply a password reset change.
@internal
class EmailAndPasswordAccount {
  // ignore: public_member_api_docs
  const EmailAndPasswordAccount(this._api);

  final API _api;

  /// TODO: write endpoint details
  Future<SetAccountInfoResponse> updateEmail(
    String newEmail,
    String idToken,
    String uid,
  ) async {
    final _response = await _api.identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        email: newEmail,
        idToken: idToken,
        localId: uid,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<SetAccountInfoResponse> updatePassword(
    String idToken, {
    String? newPassword,
  }) async {
    return _api.identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        password: newPassword,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<String> resetPassword(String? code, String? newPassword) async {
    final _response = await _api.identityToolkit.resetPassword(
      IdentitytoolkitRelyingpartyResetPasswordRequest(
        newPassword: newPassword,
        oobCode: code,
      ),
    );

    return _response.email!;
  }
}
