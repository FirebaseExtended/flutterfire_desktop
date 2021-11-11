part of firebase_auth_desktop;

/// Map from Dart package type to the platfrom interface type.
auth_dart.AuthCredential _authCredential(AuthCredential credential) {
  if (credential is EmailAuthCredential) {
    return auth_dart.EmailAuthProvider.credential(
      email: credential.email,
      password: credential.password!,
    );
  } else if (credential is GoogleAuthCredential) {
    return auth_dart.GoogleAuthProvider.credential(
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    );
  } else {
    return auth_dart.AuthCredential(
      providerId: credential.providerId,
      signInMethod: credential.signInMethod,
    );
  }
}
