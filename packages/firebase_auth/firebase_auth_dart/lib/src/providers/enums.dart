// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

/// Types of providers in Firebase.
/// Each provider has a special raw string id that is mapped to one of these types.
enum ProviderId {
  /// `password` sign-in provider.
  password,

  /// `phone` sign-in provider.
  phone,

  /// `google.com` sign-in provider.
  google,

  /// `facebook.com` sign-in provider.
  facebook,

  /// `github.com` sign-in provider.
  github,

  /// `twitter.com` sign-in provider.
  twitter,

  /// `custom` sign-in provider.
  custom,

  /// `anonymous` sign-in provider.
  anonymous,

  /// Return when the provider id isn't expected.
  unknown
}

/// Cast a string into one of a [ProviderId].
extension StringFromProviderId on ProviderId {
  /// Sign in provider [String] from [ProviderId].
  String get signInProvider {
    switch (this) {
      case ProviderId.password:
        return 'password';
      case ProviderId.phone:
        return 'phone';
      case ProviderId.facebook:
        return 'facebook.com';
      case ProviderId.github:
        return 'github.com';
      case ProviderId.twitter:
        return 'twitter.com';
      case ProviderId.custom:
        return 'custom';
      case ProviderId.anonymous:
        return 'anonymous';
      default:
        return 'unknown';
    }
  }
}

/// Cast provider Id returned from identity platform into a [ProviderId].
extension ProviderIdFromString on String {
  /// Get [ProviderId] from a [String].
  ProviderId get providerId {
    switch (this) {
      case 'password':
        return ProviderId.password;
      case 'phone':
        return ProviderId.phone;
      case 'google.com':
        return ProviderId.google;
      case 'facebook.com':
        return ProviderId.facebook;
      case 'github.com':
        return ProviderId.github;
      case 'twitter.com':
        return ProviderId.twitter;
      case 'custom':
        return ProviderId.custom;
      case 'anonymous':
        return ProviderId.anonymous;
      default:
        return ProviderId.unknown;
    }
  }
}
