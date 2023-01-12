part of firebase_storage_dart;

class StorageApiClient {
  final String bucket;

  late final http.Client _client;
  late final Uri uri;

  StorageApiClient(this.bucket, [Uri? uri]) {
    _client = http.Client();
    this.uri = uri ??
        Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o');
  }

  StorageApiClient withServiceUri(Uri uri) {
    return StorageApiClient(
      bucket,
      Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        pathSegments: [
          'v0',
          'b',
          bucket,
          'o',
        ],
      ),
    );
  }

  Uri _buildRequestUri({
    Map<String, dynamic>? queryParameters,
    List<String>? pathSegments,
  }) {
    return Uri(
      host: uri.host,
      scheme: uri.scheme,
      port: uri.port,
      pathSegments: [...uri.pathSegments, ...pathSegments ?? []],
      queryParameters: queryParameters,
    );
  }

  Future<void> delete(String fullPath) async {
    final uri = _buildRequestUri(pathSegments: [Uri.encodeComponent(fullPath)]);
    await _client.delete(uri);
  }

  Future<Map<String, dynamic>> list(
    String path, [
    ListOptions? options,
  ]) async {
    String prefix;
    if (path == '/') {
      prefix = '';
    } else {
      prefix = '$path/';
    }

    final uri = _buildRequestUri(queryParameters: {
      'prefix': Uri.encodeFull(prefix),
      'delimiter': Uri.encodeFull('/'),
    });

    final res = await _client.get(uri);
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getMetadata(String fullPath) async {
    final uri = _buildRequestUri(pathSegments: [Uri.encodeComponent(fullPath)]);

    final res = await _client.get(uri);
    return json.decode(res.body);
  }

  Uri _buildDownloadURL(Map<String, dynamic> metadata, String fullPath) {
    final tokensString = metadata['downloadTokens'] as String;
    final tokens = tokensString.split(',');
    final token = tokens[0];

    final encodedPath = Uri.encodeComponent(fullPath);
    final downloadUri = _buildRequestUri(
      pathSegments: [encodedPath],
      queryParameters: {
        'alt': 'media',
        'token': token,
      },
    );

    return downloadUri;
  }

  Future<String> getDownloadURL(String fullPath) async {
    final metadata = await getMetadata(fullPath);
    return _buildDownloadURL(metadata, fullPath).toString();
  }
}
