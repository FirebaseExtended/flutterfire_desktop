// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// Interface representing a user's metadata.
class UserMetadata {
  // ignore: public_member_api_docs
  @protected
  UserMetadata(this._creationTimestamp, this._lastSignInTime);

  final int _creationTimestamp;
  final int _lastSignInTime;

  /// When this account was created as dictated by the server clock.
  DateTime? get creationTime =>
      DateTime.fromMillisecondsSinceEpoch(_creationTimestamp);

  /// When the user last signed in as dictated by the server clock.
  ///
  /// This is only accurate up to a granularity of 2 minutes for consecutive
  /// sign-in attempts.
  DateTime? get lastSignInTime =>
      DateTime.fromMillisecondsSinceEpoch(_lastSignInTime);

  @override
  String toString() {
    return 'UserMetadata(creationTime: ${creationTime.toString()}, lastSignInTime: ${lastSignInTime.toString()})';
  }
}
