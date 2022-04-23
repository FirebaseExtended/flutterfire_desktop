// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_dynamic_calls

part of firebase_auth_dart;

/// User object wrapping the responses from identity toolkit.
class User {
  /// Return a dart user object from Google's identity toolkit response.
  User(this._user, this._auth);

  final FirebaseAuth _auth;
  final Map<String, dynamic> _user;

  /// Internally used to read the current idToken.
  String get _idToken => _user['idToken'];

  DecodedToken get _decodedIdToken => DecodedToken.fromJWTString(_idToken);

  void _setIdToken(String? idToken) {
    _user['idToken'] = idToken;
  }

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
    return _castProviderFromIdToken(IdTokenResult(_decodedIdToken)) ==
        ProviderId.anonymous;
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
    return _user['providerUserInfo']
            ?.map((userInfo) => UserInfo(userInfo.cast<String, String?>()))
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

  /// The current user's tenant ID.
  ///
  /// This is a read-only property, which indicates the tenant ID used to sign in
  /// the current user.
  /// This is null if the user is signed in from the parent project.
  String? get tenantId => throw UnimplementedError();

  /// The unique id of a user in Firebase.
  String get uid {
    return _user['localId'];
  }

  /// Unlinks a provider from a user account.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  ///
  /// **no-such-provider:**
  /// Thrown if the user does not have this provider linked or when the provider
  /// ID given does not exist.
  Future<User> unlink(String providerId) async {
    try {
      _assertSignedOut(_auth);

      final currentProviders = providerData.map((p) => p.providerId).toList();

      if (providerId.providerId == ProviderId.unknown ||
          !currentProviders.contains(providerId)) {
        throw FirebaseAuthException(AuthErrorCode.NO_SUCH_PROVIDER);
      }

      await _auth._api.userAccount.deleteLinkedAccount(_idToken, providerId);
      await reload();

      return this;
    } catch (e) {
      rethrow;
    }
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
      _assertSignedOut(_auth);

      await _auth._api.userAccount.delete(_idToken, uid);
      await _auth.signOut();
    } catch (e) {
      rethrow;
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
    _assertSignedOut(_auth);

    await _refreshIdToken(forceRefresh);

    return _idToken;
  }

  /// Returns a [IdTokenResult] containing the users JSON Web Token (JWT) and
  /// other metadata.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    _assertSignedOut(_auth);

    await _refreshIdToken(forceRefresh);

    return IdTokenResult(_decodedIdToken);
  }

  Future<void> _refreshIdToken(bool forceRefresh) async {
    if (forceRefresh || !_decodedIdToken.isValidTimestamp) {
      _setIdToken(await _auth._api.idToken.refreshIdToken(refreshToken));
      _auth._updateCurrentUserAndEvents(this);
    }
  }

  /// Links the user account with the given credentials.
  ///
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    try {
      if (credential is EmailAuthCredential) {
        final response = await _auth._api.emailAndPasswordAuth.linkWithEmail(
          _idToken,
          credential: credential,
        );

        _setIdToken(response.idToken);
        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
        );
      } else if (credential is PhoneAuthCredential) {
        final confirmationResult = ConfirmationResult(
          _auth,
          credential.verificationId!,
        );

        return await confirmationResult.confirm(credential.smsCode!);
      } else if (credential is OAuthCredential) {
        final response = await _auth._api.idpAuth.signInWithOAuthCredential(
          idToken: _idToken,
          requestUri: _auth.app.options.authDomain,
          providerId: credential.providerId,
          providerAccessToken: credential.accessToken,
          providerIdToken: credential.idToken,
          nonce: credential.rawNonce,
          providerSecret: credential.secret,
        );

        _setIdToken(response.idToken);
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
      rethrow;
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
    _assertSignedOut(_auth);

    try {
      if (credential is EmailAuthCredential) {
        if (credential.email != email) {
          throw FirebaseAuthException(AuthErrorCode.USER_MISMATCH);
        }

        final response = await _auth._api.emailAndPasswordAuth
            .signInWithEmailAndPassword(credential.email, credential.password!);

        _setIdToken(response.idToken);
        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
          additionalUserInfo: AdditionalUserInfo(
            isNewUser: false,
            profile: {
              'displayName': response.displayName,
              'photoURL': response.photoUrl
            },
            providerId: credential.providerId,
          ),
        );
      } else if (credential is GoogleAuthCredential) {
        assert(_auth.app.options.authDomain != null,
            'You should provide authDomain when trying to add Google as auth provider.');

        final response = await _auth._api.idpAuth.signInWithOAuthCredential(
          providerId: credential.providerId,
          providerIdToken: credential.idToken,
          providerAccessToken: credential.accessToken,
          requestUri: _auth.app.options.authDomain,
        );

        _setIdToken(response.idToken);
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
      } else if (credential is PhoneAuthCredential) {
        final response = await _auth._api.smsAuth.confirmPhoneNumber(
          phoneNumber: phoneNumber,
          smsCode: credential.smsCode,
          idToken: _idToken,
          verificationId: credential.verificationId,
        );

        _setIdToken(response.idToken);
        await reload();

        return UserCredential._(
          auth: _auth,
          credential: credential,
          additionalUserInfo: AdditionalUserInfo(
            isNewUser: response.isNewUser,
            providerId: credential.providerId,
          ),
        );
      } else {
        throw UnsupportedError('${credential.providerId} is not supported.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Link the current user with the given phone number.
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber,
      [RecaptchaVerifier? applicationVerifier]) async {
    try {
      return ConfirmationResult(
        _auth,
        await _auth._api.smsAuth.signInWithPhoneNumber(
          phoneNumber,
          verifier: applicationVerifier,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes the current user, if signed in.
  Future<void> reload() async {
    _assertSignedOut(_auth);

    final user = await _auth._reloadCurrentUser(_idToken);

    if (!user.containsKey('displayName')) {
      user['displayName'] = null;
    }
    if (!user.containsKey('photoUrl')) {
      user['photoUrl'] = null;
    }

    _user.addAll(user);
    _auth._updateCurrentUserAndEvents(this);
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
  /// - `email-not-found`: user doesn't exist
  Future<void> updateEmail(String newEmail) async {
    _assertSignedOut(_auth);

    try {
      await _auth._api.emailAndPasswordAccount
          .updateEmail(newEmail, _idToken, uid);
      await reload();
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a verification email to a user.
  ///
  /// The verification process is completed by calling `applyActionCode`.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `invalid-id-token`: user's credential is no longer valid. The user must sign in again.
  /// - `user-not-found`: no user record corresponding to this identifier. The user may have been deleted.
  Future<void> sendEmailVerification() async {
    _assertSignedOut(_auth);

    try {
      await _auth._api.emailAndPasswordAuth.sendVerificationEmail(_idToken);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset user password.
  ///
  /// Requires tht the user has recently been authenticated,
  /// check [User.reauthenticateWithCredential].
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `operation-not-allowed`
  ///   - Password sign-in is disabled for this project.
  /// - `user-disabled`
  ///   - The user account has been disabled by an administrator.
  Future<void> updatePassword(String newPassword) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.emailAndPasswordAccount.updatePassword(
        _idToken,
        newPassword: newPassword,
      );
      await reload();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the user's phone number.
  ///
  /// A credential can be created by verifying a phone number via
  /// [FirebaseAuth.signInWithPhoneNumber].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `invalid-verification-code`
  ///   - Thrown if the verification code of the credential is not valid.
  /// - `invalid-verification-id`
  ///   - Thrown if the verification ID of the credential is not valid.
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    _assertSignedOut(_auth);

    try {
      await _auth._api.smsAuth.confirmPhoneNumber(
        idToken: _idToken,
        smsCode: phoneCredential.smsCode,
        verificationId: phoneCredential.verificationId,
      );
      await reload();
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's displayName.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `email-not-found`: user doesn't exist
  /// TODO
  Future<void> updateDisplayName(String? displayName) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.userProfile.updateProfile(
        _idToken,
        uid,
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's photoUrl.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `email-not-found`: user doesn't exist
  /// TODO
  Future<void> updatePhotoURL(String? photoUrl) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.userProfile.updateProfile(
        _idToken,
        uid,
        photoUrl: photoUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's profile.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `email-not-found`: user doesn't exist
  /// TODO
  Future<void> updateProfile({
    String? photoUrl = '',
    String? displayName = '',
  }) async {
    try {
      _assertSignedOut(_auth);

      await _auth._api.userProfile.updateProfile(
        _idToken,
        uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      await reload();
    } catch (e) {
      rethrow;
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
    throw FirebaseAuthException(AuthErrorCode.NO_CURRENT_USER);
  }
}

ProviderId _castProviderFromIdToken(IdTokenResult idTokenResult) {
  final signInProvider = idTokenResult.signInProvider;
  return signInProvider?.providerId ?? ProviderId.unknown;
}
