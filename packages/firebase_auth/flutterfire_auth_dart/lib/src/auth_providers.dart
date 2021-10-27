// ignore_for_file: public_member_api_docs

part of flutterfire_auth_dart;

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

extension ProviderID on AuthProvider {
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
