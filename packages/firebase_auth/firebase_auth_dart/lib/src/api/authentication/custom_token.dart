part of api;

/// A response parsed from `verifyCustomToken` endpoint result.
@internal
class CustomTokenResponse extends SignInResponse {
  CustomTokenResponse._({
    required String idToken,
    required String refreshToken,
    bool isNewUser = false,
  }) : super(idToken, refreshToken, isNewUser);

  /// Construct new [CustomTokenResponse] from a sign-in json result.
  factory CustomTokenResponse.fromJson(Map<String, dynamic> json) {
    return CustomTokenResponse._(
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: (json['isNewUser'] as bool?) ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'isNewUser': isNewUser,
    };
  }
}

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyCustomToken`: exchange a custom Auth token for a `tokenId` and `refreshToken`.
@internal
class CustomTokenAuth extends APIDelegate {
  // ignore: public_member_api_docs
  const CustomTokenAuth(API api) : super(api);

  /// Sign a user using developer's custom JWT token.
  /// The response will contain a fresh `idToken` and a `refreshToken`.
  ///
  /// Common error codes:
  /// - `INVALID_CUSTOM_TOKEN`: The custom token format is incorrect or the token is
  /// invalid for some reason (e.g. expired, invalid signature etc.)
  /// - `CREDENTIAL_MISMATCH`: The custom token corresponds to a different Firebase project.
  Future<CustomTokenResponse> signInWithCustomToken(String customToken) async {
    try {
      final response = await api.identityToolkit.verifyCustomToken(
        IdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
          token: customToken,
          returnSecureToken: true,
        ),
      );

      return CustomTokenResponse.fromJson(response.toJson());
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
