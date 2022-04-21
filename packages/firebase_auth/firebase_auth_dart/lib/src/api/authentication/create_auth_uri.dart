part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `createAuthUri`:  look all providers associated with a specified email.
@internal
class CreateAuthUri extends APIDelegate {
  // ignore: public_member_api_docs
  const CreateAuthUri(API api) : super(api);

  /// Look up all providers associated with an email.
  /// Returns a list of provider Ids.
  ///
  /// Example response:
  /// ```dart
  /// ["password", "google.com"]
  /// ```
  ///
  /// Common error codes:
  /// - `INVALID_EMAIL`: The email address is badly formatted.
  Future<List<String>> fetchSignInMethodsForEmail(
    String email, {
    String? continueUri = 'http://localhost',
  }) async {
    try {
      final _response = await api.identityToolkit.createAuthUri(
        IdentitytoolkitRelyingpartyCreateAuthUriRequest(
          identifier: email,
          continueUri: continueUri,
        ),
      );

      return _response.signinMethods ?? [];
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
