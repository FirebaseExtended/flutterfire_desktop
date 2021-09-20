part of auth_interop;

/// Representation of an authentication provider.
enum _AuthProvider {
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
extension on _AuthProvider {
  // ignore: public_member_api_docs
  String get providerId {
    switch (this) {
      case _AuthProvider.password:
        return 'password';
      case _AuthProvider.phone:
        return 'phone';
      case _AuthProvider.anonymous:
        return 'anonymous';
      case _AuthProvider.google:
        return 'google.com';
      case _AuthProvider.facebook:
        return 'facebook.com';
      case _AuthProvider.twitter:
        return 'twitter.com';
      case _AuthProvider.github:
        return 'github.com';
      case _AuthProvider.custom:
        return 'custom';
    }
  }
}
