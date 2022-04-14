part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `deleteAccount`: delete a current user.
/// - `setAccountInfo`: delete a linked auth provider.
/// - `getAccountInfo`: get a user's data.
@internal
class UserAccount extends APIDelegate {
  // ignore: public_member_api_docs
  const UserAccount(API api) : super(api);

  /// TODO: write endpoint details
  Future<DeleteAccountResponse> delete(String idToken, String uid) async {
    return api.identityToolkit.deleteAccount(
      IdentitytoolkitRelyingpartyDeleteAccountRequest(
        idToken: idToken,
        localId: uid,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<SetAccountInfoResponse> deleteLinkedAccount(
    String idToken,
    String providerId,
  ) async {
    return api.identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        deleteProvider: [providerId],
      ),
    );
  }

  /// TODO: write endpoint details
  Future<UserInfo> getAccountInfo(String? idToken) async {
    final _response = await api.identityToolkit.getAccountInfo(
      IdentitytoolkitRelyingpartyGetAccountInfoRequest(idToken: idToken),
    );

    return _response.users![0];
  }
}
