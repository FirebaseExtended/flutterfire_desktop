part of api;

/// A return type from Idp authentication requests, must be extended by any other response
/// type for any operation that requires idToken.
@protected
class IdTokenResponse {
  /// Construct a new [IdTokenResponse].
  IdTokenResponse({required this.idToken, required this.refreshToken});

  /// The idToken returned from a successful authentication operation, valid only for 1 hour.
  final String idToken;

  /// Th refreshToken returned from a successful authentication operation, used to request new
  /// [idToken] if it has expired or force refreshed.
  final String refreshToken;

  /// Json representation of this object.
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'refreshToken': refreshToken,
    };
  }
}

/// Class wrapping methods that calls to the following endpoints:
/// - `securetoken.googleapis.com`: refresh a Firebase ID token.
@internal
class IdToken extends APIDelegate {
  // ignore: public_member_api_docs
  IdToken(API api) : super(api);

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  ///
  Future<String?> refreshIdToken(String? refreshToken) async {
    try {
      return await _exchangeRefreshWithIdToken(refreshToken);
    } on HttpException catch (_) {
      rethrow;
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
