part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyAssertion`: sign in or link a user with an OAuth credential.
@internal
class IdpAuth extends APIDelegate {
  // ignore: public_member_api_docs
  const IdpAuth(API api) : super(api);

  /// Sign in a user with an OAuth credential.
  ///
  /// Common error codes:
  /// - `OPERATION_NOT_ALLOWED`: The corresponding provider is disabled for this project.
  /// - `INVALID_IDP_RESPONSE`: The supplied auth credential is malformed or has expired.
  Future<VerifyAssertionResponse> signInWithOAuthCredential({
    required String providerId,
    String? idToken,
    String? requestUri,
    String? providerIdToken,
    String? providerAccessToken,
    String? providerSecret,
    String? nonce,
  }) async {
    try {
      var uri = Uri.parse(requestUri ?? '');
      if (!uri.isScheme('https')) {
        uri = uri.replace(scheme: 'https');
      }

      final postBody = <String>['providerId=$providerId'];

      if (providerIdToken != null) {
        postBody.add('id_token=$providerIdToken');
      }
      if (providerAccessToken != null) {
        postBody.add('access_token=$providerAccessToken');
      }
      if (providerSecret != null) {
        postBody.add('oauth_token_secret=$providerSecret');
      }
      if (nonce != null) {
        postBody.add('nonce=$nonce');
      }

      final response = await api.identityToolkit.verifyAssertion(
        IdentitytoolkitRelyingpartyVerifyAssertionRequest(
          idToken: idToken,
          requestUri: uri.toString(),
          postBody: postBody.join('&'),
          returnIdpCredential: true,
          returnSecureToken: true,
        ),
      );

      if (response.errorMessage != null) {
        throw DetailedApiRequestError(null, response.errorMessage);
      }

      return response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
