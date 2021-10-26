// ignore_for_file: require_trailing_commas, avoid_dynamic_calls

part of firebase_auth_dart;

/// Service layer to perform all requests with the underlying Identity Toolkit API.
class API {
  // ignore: public_member_api_docs
  API(this._apiKey, this._projectId, {http.Client? client}) {
    _client = client ?? clientViaApiKey(_apiKey);
    _identityToolkit = IdentityToolkitApi(_client).relyingparty;
  }

  late final String _apiKey;
  late final String _projectId;

  late http.Client _client;
  late RelyingpartyResource _identityToolkit;

  void _setApiClient(http.Client client) {
    _client = client;
    _identityToolkit = IdentityToolkitApi(client).relyingparty;
  }

  /// TODO: write endpoint details
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    final _response = await _identityToolkit.verifyPassword(
      IdentitytoolkitRelyingpartyVerifyPasswordRequest(
        returnSecureToken: true,
        password: password,
        email: email,
      ),
    );

    return _response.toJson();
  }

  /// TODO: write endpoint details
  Future<Map<String, dynamic>> createUserWithEmailAndPassword(
      String email, String password) async {
    final _response = await _identityToolkit.signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest(
        email: email,
        password: password,
      ),
    );
    return _response.toJson();
  }

  /// TODO: write endpoint details

  Future<Map<String, dynamic>> signInAnonymously() async {
    final _response = await _identityToolkit.signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest(),
    );

    return _response.toJson();
  }

  /// TODO: write endpoint details
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final _response = await _identityToolkit.createAuthUri(
      IdentitytoolkitRelyingpartyCreateAuthUriRequest(
        identifier: email,
        // TODO hmm?
        continueUri: 'http://localhost:8080/app',
      ),
    );

    return _response.allProviders ?? [];
  }

  /// TODO: write endpoint details
  Future sendPasswordResetEmail(String email) async {
    await _identityToolkit.getOobConfirmationCode(
      Relyingparty(
        email: email,
        requestType: 'PASSWORD_RESET',
        // TODO have to be sent, otherwise the user won't be redirected to the app.
        // continueUrl: ,
      ),
    );
  }

  /// TODO: write endpoint details
  Future resetUserPassword(String idToken, {String? newPassword}) async {
    await _identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        password: newPassword,
      ),
    );
  }

  /// TODO: write endpoint details
  Future sendSignInLinkToEmail(String email) async {
    await _identityToolkit.getOobConfirmationCode(
      Relyingparty(
        email: email,
        requestType: 'EMAIL_SIGNIN',
        // have to be sent, otherwise the user won't be redirected to the app.
        // continueUrl: ,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<Map<String, dynamic>> updateEmail(
      String newEmail, String idToken, String uid) async {
    final _response = await _identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        email: newEmail,
        idToken: idToken,
        localId: uid,
      ),
    );
    return _response.toJson();
  }

  /// TODO: write endpoint details
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> newProfile, String idToken, String uid) async {
    final _response = await _identityToolkit.setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest(
        displayName: newProfile['displayName'],
        photoUrl: newProfile['photoURL'],
        idToken: idToken,
        localId: uid,
      ),
    );
    return _response.toJson();
  }

  /// TODO: write endpoint details
  Future<Map<String, dynamic>> reloadCurrentUser(String idToken) async {
    final _response = await _identityToolkit.getAccountInfo(
      IdentitytoolkitRelyingpartyGetAccountInfoRequest(idToken: idToken),
    );

    return _response.toJson()['users'][0];
  }

  /// TODO: write endpoint details
  Future<String?> sendEmailVerification(String idToken) async {
    final _response = await _identityToolkit.getOobConfirmationCode(
      Relyingparty(requestType: 'VERIFY_EMAIL', idToken: idToken),
    );

    return _response.email;
  }

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  ///
  Future<String?> refreshIdToken(String refreshToken) async {
    try {
      return await _exchangeRefreshWithIdToken(
        refreshToken,
        _apiKey,
      );
    } on HttpException catch (_) {
      rethrow;
    } catch (exception) {
      rethrow;
    }
  }

  Future<String?> _exchangeRefreshWithIdToken(
    String? refreshToken,
    String apiKey,
  ) async {
    final _response = await http.post(
      Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$apiKey',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/x-www-form-urlencoded'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);

    return _data['access_token'];
  }

  /// TODO: write endpoint details
  Future<void> delete(String idToken, String uid) async {
    await _identityToolkit.deleteAccount(
      IdentitytoolkitRelyingpartyDeleteAccountRequest(
        idToken: idToken,
        localId: uid,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<Map> useEmulator(String host, int port) async {
    // 1. Get the emulator project configs, it must be initialized first.
    // http://localhost:9099/emulator/v1/projects/{project-id}/config
    final localEmulator = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: '/emulator/v1/projects/$_projectId/config',
    );

    http.Response response;

    try {
      response = await http.get(localEmulator);
    } on SocketException catch (e) {
      final socketException = SocketException(
        'Error happened while trying to connect to the local emulator, '
        'make sure you have it running, and you provided the correct port.',
        port: port,
        osError: e.osError,
        address: e.address,
      );

      throw socketException;
    } catch (e) {
      rethrow;
    }

    final Map emulatorProjectConfig = json.decode(response.body);

    // 3. Update the requester to use emulator
    final rootUrl = 'http://$host:$port/www.googleapis.com/';
    _identityToolkit = IdentityToolkitApi(
      clientViaApiKey(_apiKey),
      rootUrl: rootUrl,
    ).relyingparty;

    return emulatorProjectConfig;
  }
}
