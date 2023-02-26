part of firebase_storage_dart;

class StorageApiClient {
  final String bucket;
  late RetryClient client;

  StorageApiClient(this.bucket, [Uri? serviceUri]) {
    final defaultUri = Uri(
      scheme: 'https',
      host: 'firebasestorage.googleapis.com',
      pathSegments: ['v0', 'b', bucket, 'o'],
    );

    final uri = serviceUri ?? defaultUri;
    client = RetryClient(uri);
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

    client = RetryClient(emulatorUri);

    return emulatorUri;
  }

  set _idToken(String token) {
    RetryClient._authToken = token;
  }

  Future<void> delete(String fullPath) async {
    await client.request(
      method: HttpMethod.delete,
      pathSegments: [Uri.encodeComponent(fullPath)],
    );
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

    final res = await client.request(
      method: HttpMethod.get,
      queryParameters: {
        'prefix': prefix,
        'delimiter': Uri.encodeFull('/'),
        if (options?.maxResults != null)
          'maxResults': options!.maxResults.toString(),
        if (options?.pageToken != null) 'pageToken': options!.pageToken,
      },
    );

    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getMetadata(String fullPath) async {
    final res = await client.request(
      method: HttpMethod.get,
      pathSegments: [Uri.encodeComponent(fullPath)],
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> updateMetadata(
    String fullPath,
    SettableMetadata metadata,
  ) async {
    final bodyMap = {
      for (var entry in metadata.asMap().entries)
        if (entry.value != null) entry.key: entry.value,
    };

    final body = json.encode(bodyMap);
    final bodyBytes = utf8.encode(body);

    final res = await client.request(
      method: HttpMethod.patch,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      pathSegments: [Uri.encodeComponent(fullPath)],
      bodyBytes: bodyBytes,
    );

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

  Future<Uint8List> getData(Uri uri) async {
    final res = await client.request(method: HttpMethod.get, uri: uri);
    return res.bodyBytes;
  }

  Future<Stream<List<int>>> getStreamedData(
    Uri uri, {
    int? offset,
    Signal? cancelSignal,
  }) async {
    final res = await client.request(
      method: HttpMethod.get,
      uri: uri,
      headers: offset != null ? {'Range': 'bytes=$offset-'} : null,
      cancelSignal: cancelSignal,
      awaitBody: false,
    );

    return res.stream!;
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String fullPath,
    Uint8List data, {
    SettableMetadata? metadata,
    Signal? cancelSignal,
  }) async {
    final metadataJson = metadata?.asMap() ?? {};

    final builder = MultipartBuilder()
      ..add(
        'application/json; charset=utf-8',
        utf8.encode(json.encode(metadataJson)),
      )
      ..add(
        metadataJson['contentType'] as String? ?? 'application/octet-stream',
        data,
      );

    final content = builder.buildContent();

    final res = await client.request(
      method: HttpMethod.post,
      headers: {
        'Content-Type': 'multipart/related; boundary=${content.boundary}',
        'X-Goog-Upload-Protocol': 'multipart',
      },
      queryParameters: {'name': fullPath},
      bodyBytes: content.getBodyBytes(),
      cancelSignal: cancelSignal,
    );

    return json.decode(res.body);
  }

  Future<String> startChunkedUpload({
    required String fullPath,
    required int length,
    SettableMetadata? metadata,
  }) async {
    final contentType = lookupMimeType(fullPath) ?? 'application/octet-stream';

    final res = await client.request(
      method: HttpMethod.post,
      headers: {
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': length.toString(),
        'X-Goog-Upload-Header-Content-Type': contentType,
        'X-Goog-Upload-Protocol': 'resumable',
      },
      queryParameters: {
        'name': fullPath,
      },
      bodyBytes: utf8.encode(json.encode({
        'contentType': contentType,
        'name': fullPath,
        ...metadata?.asMap() ?? {},
      })),
    );

    if (res.statusCode != 200) {
      throw FirebaseStorageException._fromHttpStatusCode(res.statusCode);
    }

    final uploadId = res.headers.value('x-gupload-uploadid');

    if (uploadId == null) {
      throw FirebaseStorageException._unknown();
    }

    return uploadId;
  }

  Future<void> uploadChunk({
    required String name,
    required String uploadId,
    required int offset,
    required Uint8List data,
    bool finalize = false,
    Signal? cancelSignal,
  }) async {
    await client.request(
      method: HttpMethod.post,
      queryParameters: {
        'name': name,
        'upload_id': uploadId,
        'upload_protocol': 'resumable',
      },
      headers: {
        'X-Goog-Upload-Command': finalize ? 'upload, finalize' : 'upload',
        'X-Goog-Upload-Offset': offset.toString(),
      },
      bodyBytes: data,
      cancelSignal: cancelSignal,
    );
  }
}
