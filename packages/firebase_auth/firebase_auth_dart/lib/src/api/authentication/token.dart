part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `securetoken.googleapis.com`: refresh a Firebase ID token.
@internal
class IdToken extends APIDelegate {
  // ignore: public_member_api_docs
  IdToken(API api) : super(api);

  /// Refresh a user's IdToken using a `refreshToken`,
  /// will refresh even if the token hasn't expired.
  ///
  /// Common error codes:
  /// - `TOKEN_EXPIRED`: The user's credential is no longer valid. The user must sign in again.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  /// - `USER_NOT_FOUND`: The user corresponding to the refresh token was not found. It is likely the user was deleted.
  /// - `INVALID_REFRESH_TOKEN`: An invalid refresh token is provided.
  /// - `INVALID_GRANT_TYPE`: the grant type specified is invalid.
  /// - `MISSING_REFRESH_TOKEN`: no refresh token provided.
  /// - API key not valid. Please pass a valid API key. (invalid API key provided)
  Future<String?> refreshIdToken(String? refreshToken) async {
    try {
      return await _exchangeRefreshWithIdToken(refreshToken);
    } catch (_) {
      rethrow;
    }
  }

  Future<String?> _exchangeRefreshWithIdToken(String? refreshToken) async {
    final baseUri = api.apiConfig.emulator != null
        ? 'http://${api.apiConfig.emulator!.host}:${api.apiConfig.emulator!.port}'
            '/securetoken.googleapis.com/v1/'
        : 'https://securetoken.googleapis.com/v1/';

    final _response = await http.post(
      Uri.parse(
        '${baseUri}token?key=${api.apiConfig.apiKey}',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/json'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);

    return _data['access_token'];
  }
}
