// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls, require_trailing_commas

part of firebase_auth_dart;

// ignore: public_member_api_docs
class IdTokenResult {
  // ignore: public_member_api_docs
  @protected
  IdTokenResult(this._data);

  final Map<String, dynamic> _data;

  /// The authentication time formatted as UTC string. This is the time the user
  /// authenticated (signed in) and not the time the token was refreshed.
  DateTime? get authTime => _data['auth_time'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _data['auth_time'] * secondToMilliesecondsFactor);

  /// The time when the ID token expires.
  DateTime? get expirationTime => _data['exp'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _data['exp'] * secondToMilliesecondsFactor);

  /// The time when ID token was issued.
  DateTime? get issuedAtTime => _data['iat'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _data['iat'] * secondToMilliesecondsFactor);

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  Map<String, dynamic>? get claims => _data['claims'] == null
      ? null
      : Map<String, dynamic>.from(_data['claims']);

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  String? get signInProvider =>
      _data['firebase'] == null ? null : _data['firebase']['sign_in_provider'];

  /// The Firebase Auth ID token JWT string.
  String get token => _data['token'];

  /// Map representation of [IdTokenResult]
  Map<String, dynamic> get toMap {
    return {
      'authTimestamp': _data['auth_time'],
      'claims': _data['claims'],
      'expirationTimestamp': _data['exp'],
      'issuedAtTimestamp': _data['iat'],
      'signInProvider': _data['firebase']['sign_in_provider'],
      'token': _data['token'],
    };
  }

  @override
  String toString() {
    return '$IdTokenResult(expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, token: $token)';
  }
}
