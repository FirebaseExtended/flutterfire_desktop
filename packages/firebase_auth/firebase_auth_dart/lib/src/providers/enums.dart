/// Types of providers in Firebase.
enum ProviderId {
  password,
  phone,
  facebook,
  github,
  twitter,
  custom,
  anonymous,
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
