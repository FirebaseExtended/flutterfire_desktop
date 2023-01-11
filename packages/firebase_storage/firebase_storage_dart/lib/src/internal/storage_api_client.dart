part of firebase_storage_dart;

class StorageApiClient {
  late final http.Client _client;
  late final gapi.StorageApi _api;

  StorageApiClient(this._client, [gapi.StorageApi? api]) {
    _api = api ?? gapi.StorageApi(_client);
  }

  StorageApiClient withServiceUri(Uri uri) {
    final api = gapi.StorageApi(_client, rootUrl: '${uri.toString()}/');
    return StorageApiClient(_client, api);
  }

  Future<gapi.Objects> list(String bucket, String path) {
    _api.objects.list(bucket, prefix: path);
    return _api.objects.list(
      bucket,
      prefix: path.startsWith('/') ? path.replaceFirst('/', '') : path,
      delimiter: "/",
    );
  }
}
