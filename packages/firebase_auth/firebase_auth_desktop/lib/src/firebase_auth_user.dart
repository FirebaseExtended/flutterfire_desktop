part of firebase_auth_desktop;

/// Dart delegate implementation of [UserPlatform].
class User extends UserPlatform {
  // ignore: public_member_api_docs
  User(FirebaseAuthPlatform auth, this._user) : super(auth, _user.toMap());

  final auth_dart.User _user;

  @override
  Future<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  // TODO: implement displayName
  String? get displayName => throw UnimplementedError();

  @override
  // TODO: implement email
  String? get email => _user.email;

  @override
  // TODO: implement emailVerified
  bool get emailVerified => throw UnimplementedError();

  @override
  Future<String> getIdToken(bool forceRefresh) {
    // TODO: implement getIdToken
    throw UnimplementedError();
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) {
    // TODO: implement getIdTokenResult
    throw UnimplementedError();
  }

  @override
  // TODO: implement isAnonymous
  bool get isAnonymous => false;

  @override
  Future<UserCredentialPlatform> linkWithCredential(AuthCredential credential) {
    // TODO: implement linkWithCredential
    throw UnimplementedError();
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
  // TODO: implement phoneNumber
  String? get phoneNumber => throw UnimplementedError();

  @override
  // TODO: implement photoURL
  String? get photoURL => null;

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
  String? get refreshToken => throw UnimplementedError();

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
  // TODO: implement uid
  String get uid => _user.uid;

  @override
  Future<UserPlatform> unlink(String providerId) {
    // TODO: implement unlink
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail(String newEmail) {
    // TODO: implement updateEmail
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword(String newPassword) {
    // TODO: implement updatePassword
    throw UnimplementedError();
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(Map<String, String?> profile) {
    // TODO: implement updateProfile
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) {
    // TODO: implement verifyBeforeUpdateEmail
    throw UnimplementedError();
  }
}
