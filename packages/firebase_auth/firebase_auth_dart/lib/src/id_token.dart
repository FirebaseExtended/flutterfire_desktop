part of firebase_auth_dart;

// ignore: public_member_api_docs
class IdToken {
  // ignore: public_member_api_docs
  @protected
  IdToken(this._data) {
    _data['requestTime'] = DateTime.now();

    if (_data.containsKey('expires_in')) {
      // rename keys to match other endpoints
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
