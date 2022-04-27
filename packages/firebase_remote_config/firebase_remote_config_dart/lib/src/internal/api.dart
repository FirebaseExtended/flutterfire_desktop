// Copyright 2022 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.
part of '../../firebase_remote_config_dart.dart';

class _RemoteConfigApiClient {
  _RemoteConfigApiClient(
    this.projectId,
    this.namespace,
    this.apiKey,
    this.appId,
    this.storage,
    this.storageCache,
  );
  final _api = api.FirebaseRemoteConfigApi(Client());

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

  Future<api.RemoteConfig> fetch({
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
    final remoteConfig = await _api.projects.getRemoteConfig(projectId);
    storageCache.setLastFetchTime(DateTime.now());
    storage.setLastSuccessfulFetchResponse(remoteConfig);
    return remoteConfig;
  }
}
