// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of firebase_auth_dart;

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
class AuthCredential {
  // ignore: public_member_api_docs
  const AuthCredential({
    required this.providerId,
    required this.signInMethod,
  });

  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId;

  /// The authentication sign in method for the credential. For example,
  /// 'password', or 'emailLink'. This corresponds to the sign-in method
  /// identifier returned in fetchSignInMethodsForEmail.
  final String signInMethod;

  /// Returns the current instance as a serialized [Map].
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'signInMethod': signInMethod,
    };
  }

  @override
  String toString() =>
      'AuthCredential(providerId: $providerId, signInMethod: $signInMethod)';
}
