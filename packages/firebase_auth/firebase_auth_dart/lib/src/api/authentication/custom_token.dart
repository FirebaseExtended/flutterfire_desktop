part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyCustomToken`: exchange a custom Auth token for an ID and refresh token.
@internal
class CustomTokenAuth {
  // ignore: public_member_api_docs
  CustomTokenAuth(this._api);

  final API _api;

  /// TODO: write endpoint details
  Future<VerifyCustomTokenResponse> signInWithCustomToken(String token) async {
    final response = await _api.identityToolkit.verifyCustomToken(
      IdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
        token: token,
        returnSecureToken: true,
      ),
    );

    return response;
  }
}
