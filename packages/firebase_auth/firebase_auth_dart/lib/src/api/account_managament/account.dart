part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `deleteAccount`: delete a current user.
/// - `setAccountInfo`: delete a linked auth provider.
/// - `getAccountInfo`: get a user's data.
@internal
class UserAccount extends APIDelegate {
  // ignore: public_member_api_docs
  const UserAccount(API api) : super(api);

  /// Delete a current user account.
  ///
  /// Common error codes:
  /// - `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  /// - `USER_NOT_FOUND`: There is no user record corresponding to this identifier.
  /// The user may have been deleted.
  Future<void> delete(String idToken, String uid) {
    return api.identityToolkit.deleteAccount(
      IdentitytoolkitRelyingpartyDeleteAccountRequest(
        idToken: idToken,
        localId: uid,
      ),
    );
  }

  /// Unlink a provider from a current user.
  ///
  /// Common error codes:
  /// `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  Future<Map<String, dynamic>> deleteLinkedAccount(
    String idToken,
    String providerId,
  ) async {
    final response = await api.identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        deleteProvider: [providerId],
      ),
    );

    return response.toJson();
  }

  /// Get a user's data.
  ///
  /// Common error codes:
  /// `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  /// `USER_NOT_FOUND`: There is no user record corresponding to this identifier.
  /// The user may have been deleted.
  Future<Map<String, dynamic>> getAccountInfo(String idToken) async {
    final response = await api.identityToolkit.getAccountInfo(
      IdentitytoolkitRelyingpartyGetAccountInfoRequest(idToken: idToken),
    );

    final json = response.users![0].toJson();

    return json;
  }
}
