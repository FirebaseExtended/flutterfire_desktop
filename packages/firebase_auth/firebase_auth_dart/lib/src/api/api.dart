// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_dynamic_calls

part of firebase_auth_dart;

/// Pure Dart service layer to perform all requests
/// with the underlying Identity Toolkit API.
///
/// See: https://cloud.google.com/identity-platform/docs/use-rest-api
class API {
  // ignore: public_member_api_docs
  API(this._apiKey, this._projectId, {http.Client? client}) {
    _client = client ?? clientViaApiKey(_apiKey);
    _identityToolkit = idp.IdentityToolkitApi(_client).relyingparty;
  }

  late final String _apiKey;
  late final String _projectId;

  late http.Client _client;
  late idp.RelyingpartyResource _identityToolkit;

  EmulatorConfig? _emulator;

  void _setApiClient(http.Client client) {
    _client = client;
    _identityToolkit = idp.IdentityToolkitApi(client).relyingparty;
  }

  /// TODO: write endpoint details
  Future<idp.VerifyPasswordResponse> signInWithEmailAndPassword(
      String email, String password) async {
    final _response = await _identityToolkit.verifyPassword(
      idp.IdentitytoolkitRelyingpartyVerifyPasswordRequest(
        returnSecureToken: true,
        password: password,
        email: email,
      ),
    );

    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SignupNewUserResponse> createUserWithEmailAndPassword(
      String email, String password) async {
    final _response = await _identityToolkit.signupNewUser(
      idp.IdentitytoolkitRelyingpartySignupNewUserRequest(
        email: email,
        password: password,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SignupNewUserResponse> signInAnonymously() async {
    final _response = await _identityToolkit.signupNewUser(
      idp.IdentitytoolkitRelyingpartySignupNewUserRequest(),
    );

    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.VerifyAssertionResponse> signInWithOAuthCredential(
      {String? idToken,
      required String providerId,
      required String providerIdToken,
      String? requestUri}) async {
    final response = await _identityToolkit.verifyAssertion(
      idp.IdentitytoolkitRelyingpartyVerifyAssertionRequest(
        idToken: idToken,
        requestUri: requestUri,
        postBody: 'id_token=$providerIdToken&'
            'providerId=$providerId',
      ),
    );

    return response;
  }

  Future<void> _sendData(HttpRequest request, Object data,
      [String contentType = 'text/html']) async {
    request.response
      ..statusCode = 200
      ..headers.set('content-type', contentType)
      ..write(data);
    await request.response.close();
  }

  /// TODO: write endpoint details
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(Object) verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    @visibleForTesting String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
  }) async {
    final recaptchaResponse = await _identityToolkit.getRecaptchaParam();

    final completer = Completer<void>();
    try {
      if (_emulator != null) {
        // Send SMS code.
        final verificationCodeResponse =
            await _identityToolkit.sendVerificationCode(
                idp.IdentitytoolkitRelyingpartySendVerificationCodeRequest(
          phoneNumber: phoneNumber,
        ));

        if (verificationCodeResponse.sessionInfo != null) {
          codeSent(verificationCodeResponse.sessionInfo!, forceResendingToken);

          completer.complete();
        }
      } else {
        final address = InternetAddress.loopbackIPv4;
        final server = await HttpServer.bind(address, 0);
        final port = server.port;
        final redirectUrl = 'http://${address.host}:$port';

        server.listen((HttpRequest request) async {
          final uri = request.requestedUri;

          if (uri.path == '/' && uri.queryParameters.isEmpty) {
            return _sendData(
              request,
              recaptchaHTML(recaptchaResponse.recaptchaSiteKey,
                  recaptchaResponse.recaptchaStoken),
            );
          } else if (uri.query.contains('response')) {
            // Send SMS code.
            final verificationCodeResponse =
                await _identityToolkit.sendVerificationCode(
                    idp.IdentitytoolkitRelyingpartySendVerificationCodeRequest(
              phoneNumber: phoneNumber,
              recaptchaToken: uri.queryParameters['response'],
            ));

            if (verificationCodeResponse.sessionInfo != null) {
              codeSent(
                  verificationCodeResponse.sessionInfo!, forceResendingToken);
            }

            return _sendData(
              request,
              successHTML(),
            )
                .then(completer.complete)
                .catchError(completer.completeError)
                .whenComplete(server.close);
          }
        });

        await OpenUrlUtil().openUrl(redirectUrl);
      }
    } catch (e) {
      verificationFailed(e);
      completer.completeError(e);
    }

    return completer.future.timeout(const Duration(minutes: 2));
  }

  /// TODO: write endpoint details
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final _response = await _identityToolkit.createAuthUri(
      idp.IdentitytoolkitRelyingpartyCreateAuthUriRequest(
        identifier: email,
        // TODO hmm?
        continueUri: 'http://localhost:8080/app',
      ),
    );

    return _response.allProviders ?? [];
  }

  /// TODO: write endpoint details
  Future<String> sendPasswordResetEmail(String email,
      {String? continueUrl}) async {
    final _response = await _identityToolkit.getOobConfirmationCode(
      idp.Relyingparty(
        email: email,
        requestType: 'PASSWORD_RESET',
        continueUrl: continueUrl,
      ),
    );

    return _response.email!;
  }

  /// TODO: write endpoint details
  Future<String> confirmPasswordReset(String? code, String? newPassword) async {
    final _response = await _identityToolkit.resetPassword(
      idp.IdentitytoolkitRelyingpartyResetPasswordRequest(
        newPassword: newPassword,
        oobCode: code,
      ),
    );

    return _response.email!;
  }

  /// TODO: write endpoint details
  Future<idp.SetAccountInfoResponse> resetUserPassword(String idToken,
      {String? newPassword}) async {
    return _identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        password: newPassword,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<idp.GetOobConfirmationCodeResponse> sendSignInLinkToEmail(
      String email, String? continueUrl) async {
    return _identityToolkit.getOobConfirmationCode(
      idp.Relyingparty(
        email: email,
        requestType: 'EMAIL_SIGNIN',
        // have to be sent, otherwise the user won't be redirected to the app.
        continueUrl: continueUrl,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<idp.SetAccountInfoResponse> updateEmail(
      String newEmail, String idToken, String uid) async {
    final _response = await _identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        email: newEmail,
        idToken: idToken,
        localId: uid,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SetAccountInfoResponse> updateProfile(
      Map<String, dynamic> newProfile, String idToken, String uid) async {
    final _response = await _identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        displayName: newProfile['displayName'],
        photoUrl: newProfile['photoURL'],
        idToken: idToken,
        localId: uid,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SetAccountInfoResponse> updatePassword(
      String newPassword, String idToken) async {
    final _response = await _identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        password: newPassword,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SetAccountInfoResponse> linkWithEmail(String idToken,
      {required EmailAuthCredential credential}) async {
    return _identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        email: credential.email,
        password: credential.password,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<idp.VerifyAssertionResponse> linkWithOAuthCredential(String idToken,
      {required String providerIdToken,
      required String providerId,
      String? requestUri}) async {
    final response = await _identityToolkit.verifyAssertion(
      idp.IdentitytoolkitRelyingpartyVerifyAssertionRequest(
        idToken: idToken,
        requestUri: requestUri,
        postBody: 'id_token=$providerIdToken&providerId=$providerId',
      ),
    );

    return response;
  }

  /// TODO: write endpoint details
  Future<idp.UserInfo> getCurrentUser(String? idToken) async {
    final _response = await _identityToolkit.getAccountInfo(
      idp.IdentitytoolkitRelyingpartyGetAccountInfoRequest(idToken: idToken),
    );

    return _response.users![0];
  }

  /// TODO: write endpoint details
  Future<String?> sendEmailVerification(String idToken) async {
    final _response = await _identityToolkit.getOobConfirmationCode(
      idp.Relyingparty(requestType: 'VERIFY_EMAIL', idToken: idToken),
    );

    return _response.email;
  }

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  ///
  Future<String?> refreshIdToken(String? refreshToken) async {
    try {
      return await _exchangeRefreshWithIdToken(refreshToken);
    } on HttpException catch (_) {
      rethrow;
    } catch (exception) {
      rethrow;
    }
  }

  Future<String?> _exchangeRefreshWithIdToken(String? refreshToken) async {
    final baseUri = _emulator != null
        ? 'http://${_emulator!.host}:${_emulator!.port}/securetoken.googleapis.com/v1/'
        : 'https://securetoken.googleapis.com/v1/';

    final _response = await http.post(
      Uri.parse(
        '${baseUri}token?key=$_apiKey',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/json'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);

    return _data['access_token'];
  }

  /// TODO: write endpoint details
  Future<idp.DeleteAccountResponse> delete(String idToken, String uid) async {
    return _identityToolkit.deleteAccount(
      idp.IdentitytoolkitRelyingpartyDeleteAccountRequest(
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

    _identityToolkit = idp.IdentityToolkitApi(
      clientViaApiKey(_apiKey),
      rootUrl: rootUrl,
    ).relyingparty;
    // set the Flage to true to use the emulator for this instance.
    _emulator = EmulatorConfig.use(host, '$port');

    return emulatorProjectConfig;
  }
}

/// A type to hold the Auth Emulator configurations.
class EmulatorConfig {
  EmulatorConfig._({
    required this.port,
    required this.host,
    this.requester,
  });

  /// Initialize the Emulator Config using the host and port printed once running `firebase emulators:start`.
  factory EmulatorConfig.use(String host, String port) {
    return EmulatorConfig._(
        port: port,
        host: host,
        requester: idp.IdentityToolkitApi(
          clientViaApiKey('dummyKey'),
          rootUrl: 'http://$host:$port/www.googleapis.com/',
        ).relyingparty);
  }

  /// The port on which the emulator suite is running.
  final String host;

  /// The port on which the emulator suite is running.
  final String port;

  /// The IDP requester used to make calls to the emulator suite.
  final idp.RelyingpartyResource? requester;
}
