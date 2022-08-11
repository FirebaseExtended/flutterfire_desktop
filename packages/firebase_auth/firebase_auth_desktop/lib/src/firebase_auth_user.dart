// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'confirmation_result.dart';
import 'firebase_auth_user_credential.dart';
import 'multi_factor.dart';
import 'utils/desktop_utils.dart';

/// Dart delegate implementation of [UserPlatform].
class User extends UserPlatform {
  // ignore: public_member_api_docs
  User(FirebaseAuthPlatform auth, this._user)
      : super(auth, MultiFactorDesktop(auth), _user.toMap());

  final auth_dart.User _user;

  @override
  Future<void> delete() async {
    await _user.delete();
  }

  @override
  String? get displayName => _user.displayName;

  @override
  String? get email => _user.email;

  @override
  bool get emailVerified => _user.emailVerified;

  @override
  Future<String> getIdToken(bool forceRefresh) {
    return _user.getIdToken(forceRefresh);
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    try {
      final idTokenResult = await _user.getIdTokenResult(forceRefresh);

      return IdTokenResult(idTokenResult.toMap);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  bool get isAnonymous => _user.isAnonymous;

  @override
  Future<UserCredentialPlatform> linkWithCredential(
      AuthCredential credential) async {
    try {
      return UserCredential(
        auth,
        await _user
            .linkWithCredential(mapAuthCredentialFromPlatform(credential)),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<ConfirmationResultPlatform> linkWithPhoneNumber(String phoneNumber,
      RecaptchaVerifierFactoryPlatform applicationVerifier) async {
    try {
      final recaptchaVerifier = applicationVerifier.delegate;
      return ConfirmationResultDesktop(
        auth,
        await _user.linkWithPhoneNumber(phoneNumber, recaptchaVerifier),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> linkWithPopup(AuthProvider provider) {
    // TODO: implement linkWithPopup
    throw UnimplementedError();
  }

  @override
  UserMetadata get metadata => mapUserMetadataFromDart(_user.metadata);

  @override
  String? get phoneNumber => _user.phoneNumber;

  @override
  String? get photoURL => _user.photoURL;

  @override
  List<UserInfo> get providerData {
    return _user.providerData.map((user) => UserInfo(user.toMap())).toList();
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) async {
    try {
      return UserCredential(
        auth,
        await _user.reauthenticateWithCredential(
            mapAuthCredentialFromPlatform(credential)),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  String? get refreshToken => _user.refreshToken;

  @override
  Future<void> reload() async {
    try {
      await _user.reload();
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendEmailVerification(
      ActionCodeSettings? actionCodeSettings) async {
    try {
      await _user.sendEmailVerification();
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  String? get tenantId => _user.tenantId;

  @override
  String get uid => _user.uid;

  @override
  Future<UserPlatform> unlink(String providerId) async {
    try {
      return User(auth, await _user.unlink(providerId));
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _user.updateEmail(newEmail);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _user.updatePassword(newPassword);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    try {
      final credentials = mapPhoneCredentialFromPlatform(phoneCredential);
      await _user.updatePhoneNumber(credentials);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  /// Update the user name.
  Future<void> updateDisplayName(String? displayName) {
    return _user.updateDisplayName(displayName);
  }

  /// Update the user's profile picture.
  Future<void> updatePhotoURL(String? photoURL) {
    return _user.updatePhotoURL(photoURL);
  }

  /// Update the user's profile.
  @override
  Future<void> updateProfile(Map<String, dynamic> newProfile) {
    return _user.updateProfile(
      displayName: newProfile['displayName'],
      photoUrl: newProfile['photoURL'],
    );
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) {
    // TODO: implement verifyBeforeUpdateEmail
    throw UnimplementedError();
  }
}
