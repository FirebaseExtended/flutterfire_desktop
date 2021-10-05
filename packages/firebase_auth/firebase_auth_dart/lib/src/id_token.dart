part of firebase_auth_dart;

// ignore: public_member_api_docs
class IdToken {
  // ignore: public_member_api_docs
  @protected
  IdToken(this._data) {
    // we need this to calculate expiration & issueing time
    _data['requestTime'] = DateTime.now();

    /// There is a bit of incosistency between the endpoints
    /// that updates the [IdToken].
    ///
    /// The mthod [Auth.refreshIdToken] references an endpoint
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
    if (_data.containsKey('expires_in')) {
      _data['expiresIn'] = _data['expires_in'];
      _data['idToken'] = _data['id_token'];

      _data.remove('expires_in');
      _data.remove('id_token');
    }
  }

  final Map<String, dynamic> _data;

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

  @override
  String toString() {
    return '$IdToken(expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, token: $token)';
  }
}
