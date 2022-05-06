// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// Map from [AuthCredential] to [auth_dart.AuthCredential].
auth_dart.AuthCredential mapAuthCredentialFromPlatform(
    AuthCredential credential) {
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
  } else if (credential is TwitterAuthCredential) {
    return auth_dart.TwitterAuthProvider.credential(
      secret: credential.secret!,
      accessToken: credential.accessToken!,
    );
  } else if (credential is FacebookAuthCredential) {
    return auth_dart.FacebookAuthProvider.credential(credential.accessToken!);
  } else if (credential is GithubAuthCredential) {
    return auth_dart.GithubAuthProvider.credential(credential.accessToken!);
  } else if (credential is OAuthCredential) {
    return auth_dart.OAuthProvider(credential.providerId).credential(
      accessToken: credential.accessToken,
      idToken: credential.idToken,
      rawNonce: credential.rawNonce,
      secret: credential.secret,
    );
  } else {
    return auth_dart.AuthCredential(
      providerId: credential.providerId,
      signInMethod: credential.signInMethod,
    );
  }
}

/// Map from [PhoneAuthCredential] to [auth_dart.PhoneAuthCredential].
auth_dart.PhoneAuthCredential mapPhoneCredentialFromPlatform(
    PhoneAuthCredential credential) {
  return auth_dart.PhoneAuthProvider.credential(
    verificationId: credential.verificationId!,
    smsCode: credential.smsCode!,
  );
}

/// Map from [auth_dart.AuthCredential] to [AuthCredential].
AuthCredential mapAuthCredentialFromDart(auth_dart.AuthCredential credential) {
  if (credential is auth_dart.EmailAuthCredential) {
    return EmailAuthProvider.credential(
      email: credential.email,
      password: credential.password!,
    );
  } else if (credential is auth_dart.GoogleAuthCredential) {
    return GoogleAuthProvider.credential(
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    );
  } else if (credential is auth_dart.TwitterAuthCredential) {
    return TwitterAuthProvider.credential(
      secret: credential.idToken!,
      accessToken: credential.accessToken!,
    );
  } else if (credential is auth_dart.FacebookAuthCredential) {
    return FacebookAuthProvider.credential(credential.accessToken!);
  } else if (credential is auth_dart.GithubAuthCredential) {
    return GithubAuthProvider.credential(credential.accessToken!);
  } else if (credential is auth_dart.OAuthCredential) {
    return OAuthProvider(credential.providerId).credential(
      accessToken: credential.accessToken,
      idToken: credential.idToken,
      rawNonce: credential.rawNonce,
      secret: credential.secret,
    );
  } else {
    return AuthCredential(
      providerId: credential.providerId,
      signInMethod: credential.signInMethod,
    );
  }
}

/// Map [auth_dart.UserMetadata] to [UserMetadata].
UserMetadata mapUserMetadataFromDart(auth_dart.UserMetadata? metadata) {
  return UserMetadata(
    metadata?.creationTime?.millisecondsSinceEpoch,
    metadata?.lastSignInTime?.millisecondsSinceEpoch,
  );
}

/// Map [auth_dart.FirebaseAuthException] to [FirebaseAuthException].
FirebaseAuthException getFirebaseAuthException(Object e) {
  if (e is auth_dart.FirebaseAuthException) {
    return FirebaseAuthException(code: e.code, message: e.message);
  } else {
    // ignore: only_throw_errors
    throw e;
  }
}
