library api;

import 'package:firebaseapis/firebaseinstallations/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Configurations necessary for making all Identity Toolkit requests.
class ApiConfig {
  /// Construct [ApiConfig].
  ApiConfig(
    this.apiKey,
    this.projectId,
    this.appId,
  );

  /// The API Key associated with the Firebase project used for initialization.
  final String apiKey;

  /// The project Id associated with the Firebase project used for initialization.
  final String projectId;

  /// The Firebase app Id of the current app.
  final String appId;
}

class ApiDelegate {
  ApiDelegate._(this.apiConfig, {http.Client? client}) {
    _client = client ?? clientViaApiKey(apiConfig.apiKey);
  }

  /// Construct new or existing [API] instance for a given [APIConfig].
  factory ApiDelegate.instanceOf(ApiConfig apiConfig, {http.Client? client}) {
    return _instances.putIfAbsent(
      apiConfig,
      () => ApiDelegate._(apiConfig, client: client),
    );
  }

  /// The Api configurations of this instance.
  final ApiConfig apiConfig;

  static final Map<ApiConfig, ApiDelegate> _instances = {};

  late final http.Client _client;

  /// [FirebaseinstallationsApi] initialized with this instance's [ApiConfig].
  FirebaseinstallationsApi get installationsAPi {
    return FirebaseinstallationsApi(_client);
  }

  Future<String?> getId() async {
    final response = await installationsAPi.projects.installations.create(
      GoogleFirebaseInstallationsV1Installation(appId: apiConfig.appId),
      apiConfig.projectId,
    );

    return response.fid;
  }

  Future<String?> getAuthToken() async {
    final response = await installationsAPi.projects.installations.create(
      GoogleFirebaseInstallationsV1Installation(appId: apiConfig.appId),
      apiConfig.projectId,
    );

    return response.fid;
  }
}
