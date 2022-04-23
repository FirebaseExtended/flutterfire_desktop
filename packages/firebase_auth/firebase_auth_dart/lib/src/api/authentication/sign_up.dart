part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `signupNewUser`: sign in a user anonymously.
@internal
class SignUp extends APIDelegate {
  // ignore: public_member_api_docs
  SignUp(API api) : super(api);

  /// Sign in a user anonymously.
  ///
  /// Common error codes:
  /// - `OPERATION_NOT_ALLOWED`: Anonymous user sign-in is disabled for this project.
  Future<SignupNewUserResponse> signInAnonymously() async {
    try {
      final _response = await api.identityToolkit.signupNewUser(
        IdentitytoolkitRelyingpartySignupNewUserRequest(),
      );

      return _response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
