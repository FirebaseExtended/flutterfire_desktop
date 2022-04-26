// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

library api;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:googleapis_auth/auth_io.dart'
    if (dart.library.html) 'package:googleapis_auth/auth_browser.dart';
part 'emulator.dart';

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
}
