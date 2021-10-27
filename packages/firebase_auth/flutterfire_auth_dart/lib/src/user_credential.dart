part of flutterfire_auth_dart;

/// A UserCredential is returned from authentication requests such as
/// [`createUserWithEmailAndPassword`].
class UserCredential {
  // ignore: public_member_api_docs
  UserCredential({
    this.additionalUserInfo,
    this.credential,
    this.user,
  });

  /// Returns additional information about the user, such as whether they are a
  /// newly created one.
  final AdditionalUserInfo? additionalUserInfo;

  /// The users [AuthCredential].
  final AuthCredential? credential;

  /// Returns a [User] containing additional information and user
  /// specific methods.
  final User? user;
}
