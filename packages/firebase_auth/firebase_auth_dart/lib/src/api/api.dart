// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_dynamic_calls, use_setters_to_change_properties, implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebaseapis/identitytoolkit/v3.dart' as idp;
import 'package:firebaseapis/src/user_agent.dart';
import 'package:googleapis_auth/auth_io.dart'
    if (dart.library.html) 'package:googleapis_auth/auth_browser.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../src/providers/email_auth.dart';
import 'authentication/phone.dart';

/// A return type from Idp authentication requests, must be extended by any other response
/// type for any operation that requires idToken.
@protected
class IdTokenResponse {
  /// Construct a new [IdTokenResponse].
  IdTokenResponse({required this.idToken, required this.refreshToken});

  /// The idToken returned from a successful authentication operation, valid only for 1 hour.
  final String idToken;

  /// Th refreshToken returned from a successful authentication operation, used to request new
  /// [idToken] if it has expired or force refreshed.
  final String refreshToken;

  /// Json representation of this object.
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'refreshToken': refreshToken,
    };
  }
}

/// Configurations necessary for making all idp requests.
@protected
class APIConfig {
  /// Construct [APIConfig].
  APIConfig(this.apiKey, this.projectId);

  /// The API Key associated with the Firebase project used for initialization.
  final String apiKey;

  /// The project Id associated with the Firebase project used for initialization.
  final String projectId;

  EmulatorConfig? _emulator;

  /// Get the current [EmulatorConfig] or null.
  EmulatorConfig? get emulator => _emulator;

  /// Set a new [EmulatorConfig] or null.
  void setEmulator(String host, int port) {
    _emulator = EmulatorConfig.use(host, port);
  }
}

/// Pure Dart service layer to perform all requests
/// with the underlying Identity Toolkit API.
///
/// See: https://cloud.google.com/identity-platform/docs/use-rest-api
@protected
class API {
  // ignore: public_member_api_docs
  API(this.apiConfig, {http.Client? client}) {
    _client = client ?? clientViaApiKey(apiConfig.apiKey);
  }

  /// The API configurations of this instance.
  final APIConfig apiConfig;

  late http.Client _client;

  String? _languageCode;

  /// The current languageCode sent in the headers of all API requests.
  /// If `null`, the default Firebase Console language will be used.
  String? get languageCode => _languageCode;

  /// Change the HTTP client for the purpose of testing.
  void setApiClient(http.Client client) {
    _client = client;
  }

  /// Updates the languageCode for this instance.
  void setLanguageCode(String? languageCode) {
    _languageCode = languageCode;
    requestHeaders.addAll({'X-Firebase-Locale': languageCode ?? ''});
  }

  /// Identity platform [idp.RelyingpartyResource] initialized with this instance [APIConfig].
  @internal
  idp.RelyingpartyResource get identityToolkit {
    if (apiConfig.emulator != null) {
      return idp.IdentityToolkitApi(
        _client,
        rootUrl: apiConfig.emulator!.rootUrl,
      ).relyingparty;
    }
    return idp.IdentityToolkitApi(
      _client,
    ).relyingparty;
  }

  PhoneAuthAPI? _phoneAuthApiDelegate;

  /// A delegate used to perform all requests for phone authentication.
  ///
  /// Will lazily be initialized on first call.
  PhoneAuthAPI get phoneAuthApiDelegate =>
      _phoneAuthApiDelegate ??= PhoneAuthAPI(this);

  /// TODO: write endpoint details
  Future<idp.VerifyPasswordResponse> signInWithEmailAndPassword(
      String email, String password) async {
    final _response = await identityToolkit.verifyPassword(
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
    final _response = await identityToolkit.signupNewUser(
      idp.IdentitytoolkitRelyingpartySignupNewUserRequest(
        email: email,
        password: password,
      ),
    );
    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.SignupNewUserResponse> signInAnonymously() async {
    final _response = await identityToolkit.signupNewUser(
      idp.IdentitytoolkitRelyingpartySignupNewUserRequest(),
    );

    return _response;
  }

  /// TODO: write endpoint details
  Future<idp.VerifyAssertionResponse> signInWithOAuthCredential({
    required String providerId,
    String? idToken,
    String? requestUri,
    String? providerIdToken,
    String? providerAccessToken,
    String? providerSecret,
  }) async {
    var uri = Uri.parse(requestUri ?? '');
    if (!uri.isScheme('https')) {
      uri = uri.replace(scheme: 'https');
    }

    final postBody = <String>['providerId=$providerId'];

    if (providerIdToken != null) {
      postBody.add('id_token=$providerIdToken');
    }
    if (providerAccessToken != null) {
      postBody.add('access_token=$providerAccessToken');
    }
    if (providerSecret != null) {
      postBody.add('oauth_token_secret=$providerSecret');
    }

    final response = await identityToolkit.verifyAssertion(
      idp.IdentitytoolkitRelyingpartyVerifyAssertionRequest(
        idToken: idToken,
        requestUri: uri.toString(),
        postBody: postBody.join('&'),
        returnIdpCredential: true,
        returnSecureToken: true,
      ),
    );

    return response;
  }

  /// TODO: write endpoint details
  Future<idp.VerifyCustomTokenResponse> signInWithCustomToken(
      String token) async {
    final response = await identityToolkit.verifyCustomToken(
      idp.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
        token: token,
        returnSecureToken: true,
      ),
    );

    return response;
  }

  /// TODO: write endpoint details
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final _response = await identityToolkit.createAuthUri(
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
    final _response = await identityToolkit.getOobConfirmationCode(
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
    final _response = await identityToolkit.resetPassword(
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
    return identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        password: newPassword,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<idp.GetOobConfirmationCodeResponse> sendSignInLinkToEmail(
      String email, String? continueUrl) async {
    return identityToolkit.getOobConfirmationCode(
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
    final _response = await identityToolkit.setAccountInfo(
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
    final _response = await identityToolkit.setAccountInfo(
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
    final _response = await identityToolkit.setAccountInfo(
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
    return identityToolkit.setAccountInfo(
      idp.IdentitytoolkitRelyingpartySetAccountInfoRequest(
        idToken: idToken,
        email: credential.email,
        password: credential.password,
      ),
    );
  }

  /// TODO: write endpoint details
  Future<idp.UserInfo> getCurrentUser(String? idToken) async {
    final _response = await identityToolkit.getAccountInfo(
      idp.IdentitytoolkitRelyingpartyGetAccountInfoRequest(idToken: idToken),
    );

    return _response.users![0];
  }

  /// TODO: write endpoint details
  Future<String?> sendEmailVerification(String idToken) async {
    final _response = await identityToolkit.getOobConfirmationCode(
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
    final baseUri = apiConfig.emulator != null
        ? 'http://${apiConfig.emulator!.host}:${apiConfig.emulator!.port}/securetoken.googleapis.com/v1/'
        : 'https://securetoken.googleapis.com/v1/';

    final _response = await http.post(
      Uri.parse(
        '${baseUri}token?key=${apiConfig.apiKey}',
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
    return identityToolkit.deleteAccount(
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
      path: '/emulator/v1/projects/${apiConfig.projectId}/config',
    );

    http.Response response;

    try {
      response = await http.get(localEmulator);
    } catch (e) {
      return {};
    }

    final Map emulatorProjectConfig = json.decode(response.body);

    // set the the emulator config for this instance.
    apiConfig.setEmulator(host, port);

    return emulatorProjectConfig;
  }
}

/// A type to hold the Auth Emulator configurations.
class EmulatorConfig {
  EmulatorConfig._({
    required this.port,
    required this.host,
  });

  /// Initialize the Emulator Config using the host and port printed once running `firebase emulators:start`.
  factory EmulatorConfig.use(String host, int port) {
    return EmulatorConfig._(port: port, host: host);
  }

  /// The port on which the emulator suite is running.
  final String host;

  /// The port on which the emulator suite is running.
  final int port;

  /// The root URL used to make requests to the locally running emulator.
  String get rootUrl => 'http://$host:$port/www.googleapis.com/';
}
