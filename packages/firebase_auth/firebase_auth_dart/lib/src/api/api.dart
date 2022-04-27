// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

library api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebaseapis/identitytoolkit/v3.dart';
import 'package:firebaseapis/src/user_agent.dart';
import 'package:googleapis_auth/auth_io.dart'
    if (dart.library.html) 'package:googleapis_auth/auth_browser.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../firebase_auth_exception.dart';
import '../providers/email_auth.dart';
import '../utils/open_url.dart';
import 'errors.dart';

part 'account_managament/account.dart';
part 'account_managament/email_and_password.dart';
part 'account_managament/profile.dart';
part 'authentication/create_auth_uri.dart';
part 'authentication/custom_token.dart';
part 'authentication/email_and_password.dart';
part 'authentication/idp.dart';
part 'authentication/recaptcha/recaptcha_args.dart';
part 'authentication/recaptcha/recaptcha_html.dart';
part 'authentication/recaptcha/recaptcha_verification_server.dart';
part 'authentication/recaptcha/recaptcha_verifier.dart';
part 'authentication/sign_up.dart';
part 'authentication/sms.dart';
part 'authentication/token.dart';
part 'emulator.dart';

/// All API classes calling to Identity Toolkit API must extend this template.
abstract class APIDelegate {
  /// Construct a new [APIDelegate].
  const APIDelegate(this.api);

  /// The [API] instance containing required configurations to make the requests.
  final API api;

  /// Convert [DetailedApiRequestError] thrown by Identity Toolkit to [FirebaseAuthException].
  FirebaseAuthException makeAuthException(DetailedApiRequestError apiError) {
    try {
      final json = apiError.jsonResponse;
      var serverErrorCode = apiError.message ?? '';

      String? customMessage;

      if (json != null) {
        if (json['error'] != null &&
            // ignore: avoid_dynamic_calls
            json['error']['status'] != null) {
          // ignore: avoid_dynamic_calls
          serverErrorCode = apiError.jsonResponse!['error']['status'];
          customMessage = apiError.message;
        }

        // Solves a problem with incosistent error codes coming from the server.
        if (serverErrorCode.contains(' ')) {
          serverErrorCode = serverErrorCode.split(' ').first;
        }
      }

      final authErrorCode = ServerError.values
          .firstWhere((code) => code.name == serverErrorCode)
          .authCode;

      return FirebaseAuthException(
        authErrorCode,
        message: customMessage,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Configurations necessary for making all Identity Toolkit requests.
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

/// Response template to be returned from all sign in methods.
abstract class SignInResponse {
  /// Construct a new [SignInResponse].
  SignInResponse(
    this.idToken,
    this.refreshToken, [
    this.isNewUser = false,
  ]);

  /// User's Firebase Id Token.
  final String idToken;

  /// User's refresh token.
  final String refreshToken;

  /// Whether this user is new or not.
  final bool isNewUser;

  /// Json representation of this object.
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'refreshToken': refreshToken,
    };
  }
}

/// A return type from Identity Toolkit authentication requests, must be extended by any other response
/// type for any operation that requires idToken.
@protected
abstract class IdTokenResponse {
  /// Construct a new [IdTokenResponse].
  const IdTokenResponse({required this.idToken, required this.refreshToken});

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

/// Pure Dart service layer to perform all requests
/// with the underlying Identity Toolkit API.
///
/// See: https://cloud.google.com/identity-platform/docs/use-rest-api
@protected
class API {
  API._(this.apiConfig, {http.Client? client}) {
    _client = client ?? clientViaApiKey(apiConfig.apiKey);
  }

  /// Construct new or existing [API] instance for a given [APIConfig].
  factory API.instanceOf(APIConfig apiConfig, {http.Client? client}) {
    return _instances.putIfAbsent(
      apiConfig,
      () => API._(apiConfig, client: client),
    );
  }

  /// The API configurations of this instance.
  final APIConfig apiConfig;

  static final Map<APIConfig, API> _instances = {};

  http.Client? _client;

  String? _languageCode;

  /// The current languageCode sent in the headers of all API requests.
  /// If `null`, the default Firebase Console language will be used.
  String? get languageCode => _languageCode;

  /// Change the HTTP client for the purpose of testing.
  @internal
  // ignore: avoid_setters_without_getters
  set client(http.Client client) {
    _client = client;
  }

  /// Updates the [languageCode] for this instance.
  void setLanguageCode(String? languageCode) {
    _languageCode = languageCode;
    requestHeaders.addAll({'X-Firebase-Locale': languageCode ?? ''});
  }

  /// Identity platform [RelyingpartyResource] initialized with this instance [APIConfig].
  @internal
  RelyingpartyResource get identityToolkit {
    if (apiConfig.emulator != null) {
      return IdentityToolkitApi(
        _client!,
        rootUrl: apiConfig.emulator!.rootUrl,
      ).relyingparty;
    }
    return IdentityToolkitApi(
      _client!,
    ).relyingparty;
  }

  /// A delegate getter used to perform all requests
  /// for email and password authentication related operations.
  EmailAndPasswordAuth get emailAndPasswordAuth => EmailAndPasswordAuth(this);

  /// A delegate used to perform all requests for phone authentication.
  SmsAuth get smsAuth => SmsAuth(this);

  /// A delegate getter used to perform all requests
  /// for sign-up related operations.
  SignUp get signUp => SignUp(this);

  /// A delegate getter used to perform all requests
  /// for custom token related operations.
  CustomTokenAuth get customTokenAuth => CustomTokenAuth(this);

  /// A delegate getter used to perform all requests
  /// for Identity platform sign-in related operations.
  IdpAuth get idpAuth => IdpAuth(this);

  /// All methods calling `createAuthUri` endpoint.
  CreateAuthUri get createAuthUri => CreateAuthUri(this);

  /// A delegate used to perform all requests for account-related operations.
  UserAccount get userAccount => UserAccount(this);

  /// A delegate getter used to perform all requests
  /// for token related operations.
  IdToken get idToken => IdToken(this);

  /// A delegate getter used to perform all requests
  /// for email and password account related operations.
  EmailAndPasswordAccount get emailAndPasswordAccount =>
      EmailAndPasswordAccount(this);

  /// A delegate getter used to perform all requests
  /// for Identity platform profile related operations.
  UserProfile get userProfile => UserProfile(this);

  /// A delegate getter used to perform all requests
  /// for Identity platform profile related operations.
  AuthEmulator get emulator => AuthEmulator(apiConfig);
}
