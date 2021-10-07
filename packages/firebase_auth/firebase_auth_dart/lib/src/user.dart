// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// User object wrapping the responses from identity toolkit.
class User {
  /// Return a dart user object from Google's identity toolkit response.
  User(this._user, this._auth) : _idToken = _user['idToken'];

  final Auth _auth;
  final Map<String, dynamic> _user;
  String _idToken;

  /// Returns a JWT refresh token for the user.
  ///
  /// This property maybe `null` or empty if the underlying platform does not
  /// support providing refresh tokens.
  String? get refreshToken {
    return _user['refreshToken'];
  }

  /// Returns a JSON Web Token (JWT) used to identify the user to a Firebase
  /// service.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      if (forceRefresh) {
        _idToken = (await _auth.refreshIdToken())!;
        _auth._idTokenChangedController.add(this);
      }

      return _idToken;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a [IdTokenResult] containing the users JSON Web Token (JWT) and
  /// other metadata.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    try {
      if (forceRefresh) {
        _idToken = (await _auth.refreshIdToken())!;
        _auth._idTokenChangedController.add(this);
      }

      return IdTokenResult(_idToken.decodeJWT);
    } catch (e) {
      rethrow;
    }
  }

  /// The unique id of a user.
  String get uid {
    return _user['localId'];
  }

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  String? get email {
    return _user['email'];
  }

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  String? get displayName {
    return _user['displayName'];
  }

  /// The photo URL of a user, could be `null`.
  String? get photoURL {
    return _user['photoURL'];
  }

  /// A Map representation of this instance.
  Map<String, dynamic> toMap() => {
        'idToken': _idToken,
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
      };
}
