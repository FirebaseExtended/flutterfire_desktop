// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

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
