// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

part of flutterfire_auth_dart;

/// User object wrapping the responses from identity toolkit.
class User {
  /// Return a dart user object from Google's identity toolkit response.
  User(this._user, this._auth) : _idToken = _user['idToken'];

  final FirebaseAuth _auth;
  final Map<String, dynamic> _user;
  final String _idToken;

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  String? get displayName {
    return _user['displayName'];
  }

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  String? get email {
    return _user['email'];
  }

  /// Returns whether the users email address has been verified.
  ///
  /// To send a verification email, see [sendEmailVerification].
  ///
  /// Once verified, call [reload] to ensure the latest user information is
  /// retrieved from Firebase.
  bool get emailVerified {
    return _user['emailVerified'] ?? false;
  }

  /// Returns whether the user is a anonymous.
  bool get isAnonymous {
    // ignore: avoid_dynamic_calls
    return providerData.isEmpty;
  }

  /// Returns additional metadata about the user, such as their creation time.
  UserMetadata? get metadata {
    return UserMetadata(
        int.parse(_user['createdAt']), int.parse(_user['lastLoginAt']));
  }

  /// Returns the users phone number.
  ///
  /// This property will be `null` if the user has not signed in or been has
  /// their phone number linked.
  String? get phoneNumber {
    return _user['phoneNumber'];
  }

  /// The photo URL of a user, could be `null`.
  String? get photoURL {
    return _user['photoUrl'];
  }

  /// Returns a list of user information for each linked provider.
  List<UserInfo> get providerData {
    // ignore: avoid_dynamic_calls
    return _user['providerUserInfo']
            ?.map((userInfo) {
              // ignore: avoid_dynamic_calls
              userInfo['uid'] = uid;
              // ignore: avoid_dynamic_calls
              return UserInfo(userInfo?.cast<String, String?>());
            })
            ?.toList()
            ?.cast<UserInfo>() ??
        [];
  }

  /// Returns a JWT refresh token for the user.
  ///
  /// This property maybe `null` or empty if the underlying platform does not
  /// support providing refresh tokens.
  String? get refreshToken {
    return _user['refreshToken'];
  }

  /// The unique id of a user in Firebase.
  String get uid {
    return _user['localId'];
  }

  /// Deletes and signs out the user.
  ///
  /// **Important**: this is a security-sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, ask the
  /// user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  ///
  Future<void> delete() async {
    try {
      await _auth._api.delete(_idToken, uid);
      await _auth.signOut();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Returns a JSON Web Token (JWT) used to identify the user to a Firebase
  /// service.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<String> getIdToken([bool forceRefresh = false]) async {
    await _refreshIdToken(forceRefresh);

    return _idToken;
  }

  /// Returns a [IdTokenResult] containing the users JSON Web Token (JWT) and
  /// other metadata.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    await _refreshIdToken(forceRefresh);

    return IdTokenResult(_idToken.decodeJWT);
  }

  Future _refreshIdToken(bool forceRefresh) async {
    if (forceRefresh || _idToken.expirationTime.isBefore(DateTime.now())) {
      _user['idToken'] = await _auth.refreshIdToken();
      _auth._idTokenChangedController.add(this);
    }
  }

  /// Links the user account with the given credentials.
  ///
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    try {
      if (credential is EmailAuthCredential) {
        await _auth._api.linkWithEmail(
          _idToken,
          credential: credential,
        );

        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
        );
      } else if (credential is GoogleAuthCredential) {
        final response = await _auth._api.linkWithOAuthCredential(
          _idToken,
          providerId: credential.providerId,
          providerIdToken: credential.idToken!,
          requestUri: _auth.app.options.authDomain,
        );

        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
          additionalUserInfo: AdditionalUserInfo(
            isNewUser: response.isNewUser ?? false,
            providerId: response.providerId,
            username: response.screenName,
            profile: {
              'displayName': response.displayName,
              'photoURL': response.photoUrl,
            },
          ),
        );
      } else {
        throw UnsupportedError('${credential.providerId} is not supported.');
      }
    } catch (e) {
      // TODO
      throw _auth.getException(e);
    }
  }

  /// Re-authenticates a user using a fresh credential.
  ///
  /// Use before operations such as [User.updatePassword] that require tokens
  /// from recent sign-in attempts.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  ///
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    try {
      if (credential is EmailAuthCredential) {
        await _auth._api
            .signInWithEmailAndPassword(credential.email, credential.password!);
        return UserCredential._(
          auth: _auth,
          credential: credential,
        );
      } else if (credential is GoogleAuthCredential) {
        final response = await _auth._api.signInWithOAuthCredential(
          idToken: _idToken,
          providerId: credential.providerId,
          providerIdToken: credential.idToken!,
          requestUri: _auth.app.options.authDomain,
        );

        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
          additionalUserInfo: AdditionalUserInfo(
            isNewUser: response.isNewUser ?? false,
            profile: {
              'displayName': response.displayName,
              'photoURL': response.photoUrl
            },
            providerId: response.providerId,
            username: response.screenName,
          ),
        );
      } else {
        throw UnsupportedError('${credential.providerId} is not supported.');
      }
    } catch (e) {
      // TODO
      throw _auth.getException(e);
    }
  }

  /// Refreshes the current user, if signed in.
  Future<void> reload() async {
    _assertSignedOut(_auth);

    _user.addAll(await _auth._reloadCurrentUser(_idToken));
    _auth.updateCurrentUserAndEvents(_auth.currentUser);
  }

  /// Updates the user's email address.
  ///
  /// An email will be sent to the original email address (if it was set) that
  /// allows to revoke the email address change, in order to protect them from
  /// account hijacking.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, ask the
  /// user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  Future<void> updateEmail(String newEmail) async {
    _assertSignedOut(_auth);

    try {
      await _auth._api.updateEmail(newEmail, _idToken, uid);
      await reload();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Sends a verification email to a user.
  ///
  /// The verification process is completed by calling `applyActionCode`.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `INVALID_ID_TOKEN`: user's credential is no longer valid. The user must sign in again.
  /// - `USER_NOT_FOUND`: no user record corresponding to this identifier. The user may have been deleted.
  Future<void> sendEmailVerification() async {
    _assertSignedOut(_auth);

    try {
      await _auth._api.sendEmailVerification(_idToken);
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Updates the user's password.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  ///   user to have recently signed in. If this requirement isn't met, ask the
  ///   user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// TODO
  Future<void> updatePassword(String newPassword) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.updatePassword(newPassword, _idToken);
      await reload();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Update user's displayName.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  /// TODO
  Future<void> updateDisplayName(String? displayName) async {
    try {
      _assertSignedOut(_auth);
      await _auth._api
          .updateProfile({'displayName': displayName}, _idToken, uid);
      await reload();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Update user's photoURL.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  /// TODO
  Future<void> updatePhotoURL(String? photoURL) async {
    try {
      _assertSignedOut(_auth);
      await _auth._api.updateProfile({'photoURL': photoURL}, _idToken, uid);
      await reload();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// Update user's profile.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  /// TODO
  Future<void> updateProfile(Map<String, dynamic> newProfile) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.updateProfile(newProfile, _idToken, uid);
      await reload();
    } catch (e) {
      throw _auth.getException(e);
    }
  }

  /// A Map representation of this instance.
  Map<String, dynamic> toMap() => _user;
}

/// Throws if any auth method is called with no user signed in.
@protected
void _assertSignedOut(FirebaseAuth instance) {
  if (instance.currentUser != null) {
    return;
  } else {
    throw FirebaseAuthException.fromErrorCode(ErrorCode.userNotSignedIn);
  }
}
