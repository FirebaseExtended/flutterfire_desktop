part of firebase_storage_dart;

class StorageApiClient {
  late final http.Client _client;
  late final gapi.StorageApi _api;
  final String bucket;

  StorageApiClient(this.bucket, this._client, [gapi.StorageApi? api]) {
    _api = api ?? gapi.StorageApi(_client);
  }

  StorageApiClient withServiceUri(Uri uri) {
    final api = gapi.StorageApi(_client, rootUrl: '${uri.toString()}/');
    return StorageApiClient(bucket, _client, api);
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
      includeTrailingDelimiter: false,
    );

    return res;
  }
}
