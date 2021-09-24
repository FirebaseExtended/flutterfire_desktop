part of firebase_auth_dart;

/// Representation of an authentication provider.
enum AuthProvider {
  password,
  phone,
  anonymous,
  google,
  facebook,
  twitter,
  github,
  custom
}

// ignore: public_member_api_docs
extension ProviderID on AuthProvider {
  // ignore: public_member_api_docs
  String get providerId {
    switch (this) {
      case AuthProvider.password:
        return 'password';
      case AuthProvider.phone:
        return 'phone';
      case AuthProvider.anonymous:
        return 'anonymous';
      case AuthProvider.google:
        return 'google.com';
      case AuthProvider.facebook:
        return 'facebook.com';
      case AuthProvider.twitter:
        return 'twitter.com';
      case AuthProvider.github:
        return 'github.com';
      case AuthProvider.custom:
        return 'custom';
    }
  }
}
