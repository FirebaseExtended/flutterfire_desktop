part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `setAccountInfo`: change a user's displayName or photoUrl.
@protected
class UserProfile extends APIDelegate {
  // ignore: public_member_api_docs
  const UserProfile(API api) : super(api);

  /// Update a user's profile (display name / photo URL).
  ///
  /// Common error codes:
  /// - `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  Future<SetAccountInfoResponse> updateProfile(
    String idToken,
    String uid, {
    String? photoUrl = '',
    String? displayName = '',
  }) async {
    try {
      final response = await api.identityToolkit.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest(
          displayName: displayName == '' ? null : displayName,
          photoUrl: photoUrl == '' ? null : photoUrl,
          idToken: idToken,
          localId: uid,
          returnSecureToken: true,
          deleteAttribute: [
            if (photoUrl == null) 'PHOTO_URL',
            if (displayName == null) 'DISPLAY_NAME'
          ],
        ),
      );
      return response;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
