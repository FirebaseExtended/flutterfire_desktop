part of firebase_storage_dart;

class StorageApiClient {
  final String bucket;
  late HttpClient client;

  StorageApiClient(this.bucket, [Uri? serviceUri]) {
    final defaultUri = Uri(
      scheme: 'https',
      host: 'firebasestorage.googleapis.com',
      pathSegments: ['v0', 'b', bucket, 'o'],
    );

    final uri = serviceUri ?? defaultUri;
    client = HttpClient(uri);
  }

  Uri useEmulator(String host, int port) {
    client.dispose();

    final pathSegments = ['v0', 'b', bucket, 'o'];
    final emulatorUri = Uri(
      scheme: 'http',
      host: host,
      port: port,
      pathSegments: pathSegments,
    );

    client = HttpClient(emulatorUri);

    return emulatorUri;
  }

  Future<void> delete(String fullPath) async {
    await client.delete(pathSegments: [Uri.encodeComponent(fullPath)]);
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

    final res = await client.get(
      queryParameters: {
        'prefix': Uri.encodeFull(prefix),
        'delimiter': Uri.encodeFull('/'),
      },
    );

    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getMetadata(String fullPath) async {
    final res = await client.get(pathSegments: [Uri.encodeComponent(fullPath)]);
    return json.decode(res.body);
  }

  Uri _buildDownloadURL(Map<String, dynamic> metadata, String fullPath) {
    final tokensString = metadata['downloadTokens'] as String;
    final tokens = tokensString.split(',');
    final token = tokens[0];

    final encodedPath = Uri.encodeComponent(fullPath);
    final downloadUri = client.getRequestUri(
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

  Future<void> uploadMultipart(String fullPath, Uint8List data) async {
    await client.postMultipart(pathSegments: [
      Uri.encodeComponent(fullPath)
    ], queryParameters: {
      'uploadType': 'multipart',
    }, files: [
      http.MultipartFile.fromBytes(
        'file',
        data,
        filename: fullPath,
      ),
    ]);
  }
}
