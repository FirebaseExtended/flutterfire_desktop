// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;

/// Map from [AuthCredential] to [auth_dart.AuthCredential].
auth_dart.AuthCredential mapAuthCredential(AuthCredential credential) {
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

/// Map [auth_dart.FirebaseAuthException] to [FirebaseAuthException].
Exception mapExceptionType(Object e) {
  if (e is auth_dart.FirebaseAuthException) {
    return FirebaseAuthException(code: e.code, message: e.message);
  } else {
    return Exception(e);
  }
}
