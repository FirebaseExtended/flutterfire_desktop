// Copyright 2022 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.
// ignore_for_file: public_member_api_docs, library_private_types_in_public_api

part of '../../firebase_remote_config_dart.dart';

@visibleForTesting
class RemoteConfigApiClient {
  RemoteConfigApiClient(
    this.projectId,
    this.namespace,
    this.apiKey,
    this.appId,
    this.storage,
    this.storageCache,
  );
  Client get httpClient => _httpClient;
  final _httpClient = Client();

  final _RemoteConfigStorage storage;
  final _RemoteConfigStorageCache storageCache;
  final String projectId;
  final String appId;
  final String namespace;
  final String apiKey;

  bool isCachedDataFresh(
    Duration cacheMaxAge,
    DateTime? lastSuccessfulFetchTimestamp,
  ) {
    if (lastSuccessfulFetchTimestamp == null) {
      return false;
    }

    final cacheAgeMillis = DateTime.now().millisecondsSinceEpoch -
        lastSuccessfulFetchTimestamp.millisecondsSinceEpoch;
    return cacheAgeMillis <= cacheMaxAge.inMilliseconds;
  }

  Future<Map> fetch({
    String? eTag,
    required Duration cacheMaxAge,
  }) async {
    final lastSuccessfulFetchTimestamp = storage.lastFetchTime;
    final lastSuccessfulFetchResponse =
        storage.getLastSuccessfulFetchResponse();

    if (lastSuccessfulFetchResponse != null &&
        isCachedDataFresh(cacheMaxAge, lastSuccessfulFetchTimestamp)) {
      return lastSuccessfulFetchResponse;
    }

    // TODO: Handle errors in fetch
    final response = await _httpClient.post(
      Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/namespaces/firebase:fetch?key=$apiKey',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Content-Encoding': 'gzip',
        'If-None-Match': eTag ?? '*'
      },
      body: json.encode({
        // TODO: Sync this with pubspec.yaml
        'sdk_version': '0.1.0',
        // TODO: Replace this with installation id
        'app_instance_id': '1',
        'app_id': appId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch remote config: ${response.statusCode} ${response.body}',
      );
    }

    final remoteConfig = json.decode(response.body);
    storageCache.setLastFetchTime(DateTime.now());

    storage.setLastSuccessfulFetchResponse(remoteConfig);
    return remoteConfig;
  }
}
