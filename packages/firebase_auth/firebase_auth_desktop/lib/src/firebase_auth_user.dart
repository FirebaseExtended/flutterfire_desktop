// ignore_for_file: require_trailing_commas

part of firebase_auth_desktop;

/// Dart delegate implementation of [UserPlatform].
class User extends UserPlatform {
  // ignore: public_member_api_docs
  User(FirebaseAuthPlatform auth, this._user) : super(auth, _user.toMap());

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
      // TODO(pr-mais):
      rethrow;
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
        await _user.linkWithCredential(_authCredential(credential)),
      );
    } catch (e) {
      // TODO(pr-mais): handle Dart exception
      rethrow;
    }
  }

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

  @override
  Future<ConfirmationResultPlatform> linkWithPhoneNumber(String phoneNumber,
      RecaptchaVerifierFactoryPlatform applicationVerifier) {
    // TODO: implement linkWithPhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> linkWithPopup(AuthProvider provider) {
    // TODO: implement linkWithPopup
    throw UnimplementedError();
  }

  @override
  // TODO: implement metadata
  UserMetadata get metadata => throw UnimplementedError();

  @override
  String? get phoneNumber => _user.phoneNumber;

  @override
  String? get photoURL => _user.photoURL;

  @override
  // TODO: implement providerData
  List<UserInfo> get providerData => throw UnimplementedError();

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) {
    // TODO: implement reauthenticateWithCredential
    throw UnimplementedError();
  }

  @override
  // TODO: implement refreshToken
  String? get refreshToken => _user.refreshToken;

  @override
  Future<void> reload() {
    // TODO: implement reload
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification(ActionCodeSettings? actionCodeSettings) {
    // TODO: implement sendEmailVerification
    throw UnimplementedError();
  }

  @override
  // TODO: implement tenantId
  String? get tenantId => throw UnimplementedError();

  @override
  String get uid => _user.uid;

  @override
  Future<UserPlatform> unlink(String providerId) {
    // TODO: implement unlink
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _user.updateEmail(newEmail);
    } catch (e) {
      // TODO(pr-mais):
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _user.updatePassword(newPassword);
    } catch (e) {
      // TODO(pr-mais):
      rethrow;
    }
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
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
    return _user.updateProfile(newProfile);
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) {
    // TODO: implement verifyBeforeUpdateEmail
    throw UnimplementedError();
  }
}
