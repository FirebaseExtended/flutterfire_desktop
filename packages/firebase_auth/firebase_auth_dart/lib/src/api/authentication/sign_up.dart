part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `signupNewUser`: sign in a user anonymously.
@internal
class SignUp {
  // ignore: public_member_api_docs
  SignUp(this._api);

  final API _api;

  /// TODO: write endpoint details
  Future<SignupNewUserResponse> signInAnonymously() async {
    final _response = await _api.identityToolkit.signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest(),
    );

    return _response;
  }
}
