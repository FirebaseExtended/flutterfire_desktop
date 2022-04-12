part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `createAuthUri`:  look all providers associated with a specified email.
@internal
class CreateAuthUri {
  // ignore: public_member_api_docs
  CreateAuthUri(this._api);

  final API _api;

  /// Look all providers associated with a specified email.
  /// Returns a list of provider Ids.
  ///
  /// Example response:
  /// ```dart
  /// ["password", "google.com"]
  /// ```
  ///
  /// Common error codes:
  /// - `INVALID_EMAIL`: The email address is badly formatted.
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final _response = await _api.identityToolkit.createAuthUri(
      IdentitytoolkitRelyingpartyCreateAuthUriRequest(
        identifier: email,
        // TODO hmm?
        continueUri: 'http://localhost:8080/app',
      ),
    );

    return _response.allProviders ?? [];
  }
}
