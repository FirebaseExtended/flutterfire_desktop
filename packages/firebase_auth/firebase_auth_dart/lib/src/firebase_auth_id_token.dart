part of firebase_auth_dart;

// ignore: public_member_api_docs
class IdToken {
  // ignore: public_member_api_docs
  @protected
  IdToken(this._data, this._auth) {
    _refreshTime();
    _fixKeys(_data);
  }

  /// There is a bit of incosistency between the endpoints
  /// that updates the [IdToken].
  ///
  /// The mthod [refreshIdToken] references an endpoint
  /// which has the following response payload:
  /// ```
  /// {
  ///   'expires_in': 3500,
  ///   'id_token': 'TOKEN'
  /// }
  /// ```
  ///
  /// Other methods have the following payload:
  /// ```
  /// {
  ///   'expiresIn': 3500,
  ///   'IdToken': 'TOKEN',
  /// }
  /// ```
  void _fixKeys(Map<String, dynamic> data) {
    if (data.containsKey('expires_in')) {
      data['expiresIn'] = data['expires_in'];
      data['idToken'] = data['id_token'];

      data.remove('expires_in');
      data.remove('id_token');
    }
  }

  Map<String, dynamic> _data;
  final Auth _auth;

  /// The time when the ID token expires.
  DateTime? get expirationTime => _data['requestTime'] is DateTime
      // ignore: avoid_dynamic_calls
      ? _data['requestTime']
          .add(Duration(seconds: int.parse(_data['expiresIn'])))
      : null;

  /// The time when ID token was issued.
  DateTime? get issuedAtTime =>
      _data['requestTime'] is DateTime ? _data['requestTime'] : null;

  /// The Firebase Auth ID token JWT string.
  String get token => _data['idToken'];

  /// We need this to calculate expiration & issueing time
  void _refreshTime() {
    _data['requestTime'] = DateTime.now();
  }

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  Future<String?> refreshIdToken(bool foreceRefresh) async {
    try {
      if (expirationTime!.isBefore(DateTime.now()) || foreceRefresh) {
        _refreshTime();

        _data = await _exchangeRefreshWithIdToken(
          _auth.currentUser!.refreshToken,
          _auth.options.apiKey,
        );
      }
    } on HttpException catch (_) {
      rethrow;
    } catch (exception) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _exchangeRefreshWithIdToken(
    String? refreshToken,
    String apiKey,
  ) async {
    final _response = await http.post(
      Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$apiKey',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/x-www-form-urlencoded'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);
    _fixKeys(_data);

    return _data;
  }

  @override
  String toString() {
    return '$IdToken(expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, token: $token)';
  }
}
