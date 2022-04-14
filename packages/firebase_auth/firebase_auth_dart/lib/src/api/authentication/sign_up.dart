part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `signupNewUser`: sign in a user anonymously.
@internal
class SignUp extends APIDelegate {
  // ignore: public_member_api_docs
  SignUp(API api) : super(api);

  /// TODO: write endpoint details
  Future<SignupNewUserResponse> signInAnonymously() async {
    final _response = await api.identityToolkit.signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest(),
    );

    return _response;
  }
}
