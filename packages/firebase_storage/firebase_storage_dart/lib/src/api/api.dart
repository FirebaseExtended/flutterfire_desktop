// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

library api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart/src/api/errors.dart';
import 'package:firebase_storage_dart/src/data_models/list_options.dart';
import 'package:firebase_storage_dart/src/data_models/put_string_format.dart';
import 'package:firebase_storage_dart/src/data_models/settable_metadata.dart';
import 'package:firebase_storage_dart/src/firebase_storage_exception.dart';
import 'package:firebase_storage_dart/src/implementations/location.dart';
import 'package:firebase_storage_dart/src/implementations/urls.dart';
import 'package:firebaseapis/firebasestorage/v1beta.dart';
import 'package:firebaseapis/src/user_agent.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:googleapis_auth/auth_io.dart'
    if (dart.library.html) 'package:googleapis_auth/auth_browser.dart';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
part 'emulator.dart';
part 'reference_api.dart';
part 'ref_api.dart';

/// All API classes calling to IDP API must extend this template.
abstract class APIDelegate {
  /// Construct a new [APIDelegate].
  const APIDelegate(this.api);

  /// The [API] instance containing required configurations to make the requests.
  final API api;

  /// Convert [DetailedApiRequestError] thrown by idp to [FirebaseStorageException].
  FirebaseStorageException makeStorageException(
      DetailedApiRequestError apiError) {
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

      final storageErrorCode = StorageErrorCode.values
          .firstWhere((code) => code.name == serverErrorCode);

      return FirebaseStorageException(
        storageErrorCode,
        message: customMessage,
      );
    } catch (e) {
      rethrow;
    }
  }

  FirebaseStorageException handleResponseErrorCodes(
      int errorStatus, String ErrorText, StorageErrorCode error) {
    StorageErrorCode storageErrorCode;
    if (errorStatus == 401) {
      if (
          // This exact message string is the only consistent part of the
          // server's error response that identifies it as an App Check error.
          ErrorText.contains('Firebase App Check token is invalid')) {
        storageErrorCode = StorageErrorCode.UNAUTHORIZED_APP;
      } else {
        storageErrorCode = StorageErrorCode.UNAUTHENTICATED;
      }
    } else {
      if (errorStatus == 402) {
        storageErrorCode = StorageErrorCode.QUOTA_EXCEEDED;
      } else {
        if (errorStatus == 403) {
          storageErrorCode = StorageErrorCode.UNAUTHORIZED;
        } else {
          storageErrorCode = error;
        }
      }
    }
    return FirebaseStorageException(
      storageErrorCode,
      message: ErrorText,
    );
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

  /// Identity platform [ProjectsResource] initialized with this instance [APIConfig].
  @internal
  ProjectsResource get firebaseStorage {
    if (apiConfig.emulator != null) {
      return FirebasestorageApi(
        _client!,
        rootUrl: apiConfig.emulator!.rootUrl,
      ).projects;
    }
    return FirebasestorageApi(
      _client!,
    ).projects;
  }

  /// A delegate getter used to perform all requests
  /// for Identity platform profile related operations.
  StorageEmulator get emulator => StorageEmulator(apiConfig);

  commons.ApiRequester get _requester {
    if (apiConfig.emulator != null) {
      return commons.ApiRequester(
          _client!, apiConfig.emulator!.rootUrl, '', requestHeaders);
    }
    return commons.ApiRequester(_client!,
        'https://firebasestorage.googleapis.com/', '', requestHeaders);
  }

  RefApi get refernceApi => RefApi(this);
}
