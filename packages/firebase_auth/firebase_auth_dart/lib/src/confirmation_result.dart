// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of firebase_auth_dart;

/// Interface for [ConfirmationResult] implementations.
///
/// A confirmation result is a response from phone-number sign-in methods.
class ConfirmationResult {
  /// Creates a new [ConfirmationResult] instance.
  ConfirmationResult(this._auth, this.verificationId);

  /// The phone number authentication operation's verification ID.
  ///
  /// This can be used along with the verification code to initialize a phone
  /// auth credential.
  final String verificationId;

  final FirebaseAuth _auth;

  /// Finishes a phone number sign-in, link, or reauthentication, given the code
  /// that was sent to the user's mobile device.
  Future<UserCredential> confirm(String verificationCode) async {
    try {
      final response = await _auth._api.smsAuth.confirmPhoneNumber(
        smsCode: verificationCode,
        verificationId: verificationId,
        idToken: _auth.currentUser?._idToken,
      );

      if (response.temporaryProof != null) {
        throw FirebaseAuthException(AuthErrorCode.NEED_CONFIRMATION);
      }

      final userData =
          await _auth._api.userAccount.getAccountInfo(response.idToken);

      // Map the json response to an actual user.
      final user = User(userData..addAll(response.toJson()), _auth);

      _auth._updateCurrentUserAndEvents(user, true);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: verificationCode,
      );

      return UserCredential._(
        auth: _auth,
        credential: credential,
        additionalUserInfo: AdditionalUserInfo(
          isNewUser: response.isNewUser,
          providerId: credential.providerId,
          username: userData['screenName'],
          profile: {
            'displayName': userData['displayName'],
            'photoUrl': userData['photoUrl']
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
