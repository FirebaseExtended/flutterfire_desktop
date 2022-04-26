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
  );

  final String projectId;
  final String appId;
  final String namespace;
  final String apiKey;
  Future<void> fetch({String? eTag}) async {
    // TODO: Firebase installations
    final client = Client();
    final response = await client.post(
      Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1'
        '/projects/$projectId/namespaces/$namespace:fetch?key=$apiKey',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Content-Encoding': 'gzip',
        // Deviates from pure decorator by not passing max-age header since we don't currently have
        // service behavior using that header.
        'If-None-Match': eTag ?? '*'
      },
      body: jsonEncode({
        // 'sdk_version': this.sdkVersion,
        // 'app_instance_id': installationId,
        // 'app_instance_id_token': installationToken,
        'app_id': appId,
        // 'language_code': getUserLanguage()
      }),
    );
    // TODO: Timeout
  }
}
