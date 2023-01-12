part of firebase_storage_dart;

class StorageApiClient {
  late final http.Client _client;
  late final gapi.StorageApi _api;
  final String bucket;

  StorageApiClient(this.bucket, this._client, [gapi.StorageApi? api]) {
    _api = api ??
        gapi.StorageApi(
          _client,
          rootUrl: 'https://firebasestorage.googleapis.com/',
          servicePath: 'v0/',
        );
  }

  StorageApiClient withServiceUri(Uri uri) {
    final api = gapi.StorageApi(
      _client,
      rootUrl: '${uri.toString()}/',
      servicePath: 'v0/',
    );

    return StorageApiClient(bucket, _client, api);
  }

  Future<void> delete(String fullPath) async {
    await _api.objects.delete(bucket, fullPath);
  }

  Future<gapi.Objects> list(
    String path, [
    ListOptions? options,
  ]) async {
    String prefix;
    if (path == '/') {
      prefix = '';
    } else {
      prefix = '$path/';
    }

    final res = await _api.objects.list(
      bucket,
      prefix: prefix,
      delimiter: '/',
      maxResults: options?.maxResults,
      endOffset: options?.pageToken,
    );

    return res;
  }

  Future<FullMetadata> getMetadata(String fullPath) async {
    final object = await _api.objects.get(bucket, fullPath) as gapi.Object;
    return FullMetadata._fromObject(fullPath, object);
  }
}
