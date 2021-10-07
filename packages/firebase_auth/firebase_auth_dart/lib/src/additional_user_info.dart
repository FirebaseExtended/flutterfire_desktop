part of firebase_auth_dart;

// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A structure containing additional user information from a federated identity
/// provider.
class AdditionalUserInfo {
  // ignore: public_member_api_docs
  AdditionalUserInfo({
    required this.isNewUser,
    this.profile,
    this.providerId,
    this.username,
  });

  /// Whether the user account has been recently created.
  final bool isNewUser;

  /// A [Map] containing additional profile information from the identity
  /// provider.
  final Map<String, dynamic>? profile;

  /// The federated identity provider ID.
  final String? providerId;

  /// The username given from the federated identity provider.
  final String? username;

  @override
  String toString() {
    return '$AdditionalUserInfo('
        'isNewUser: $isNewUser, '
        'profile: $profile, '
        'providerId: $providerId, '
        'username: $username)';
  }
}
