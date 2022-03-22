// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls, require_trailing_commas

part of firebase_auth_dart;

// ignore: public_member_api_docs
class IdTokenResult {
  // ignore: public_member_api_docs
  @protected
  IdTokenResult(this._decodedToken);

  final DecodedToken _decodedToken;

  /// The authentication time formatted as UTC string. This is the time the user
  /// authenticated (signed in) and not the time the token was refreshed.
  DateTime? get authTime => _decodedToken.claims['auth_time'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _decodedToken.claims['auth_time'] * secondToMilliesecondsFactor);

  /// The time when the ID token expires.
  DateTime? get expirationTime => _decodedToken.claims['exp'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _decodedToken.claims['exp'] * secondToMilliesecondsFactor);

  /// The time when ID token was issued.
  DateTime? get issuedAtTime => _decodedToken.claims['iat'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _decodedToken.claims['iat'] * secondToMilliesecondsFactor);

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  Map<String, dynamic>? get claims =>
      Map<String, dynamic>.from(_decodedToken.claims);

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  String? get signInProvider => _decodedToken.claims['firebase'] == null
      ? null
      : _decodedToken.claims['firebase']['sign_in_provider'];

  /// The Firebase Auth ID token JWT string.
  String get token => _decodedToken.token;

  /// Map representation of [IdTokenResult]
  Map<String, dynamic> get toMap {
    return {
      'authTimestamp': authTime,
      'claims': claims,
      'expirationTimestamp': expirationTime,
      'issuedAtTime': issuedAtTime,
      'signInProvider': signInProvider,
      'token': token,
    };
  }

  @override
  String toString() {
    return '$IdTokenResult(expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, token: $token)';
  }
}
