part of firebase_storage_dart;

/// Represents a reference to a Google Cloud Storage object. Developers can
/// upload, download, and delete objects, as well as get/set object metadata.
class Reference {
  final FirebaseStorage storage;
  final String bucket;

  late final String fullPath;
  late final String name;

  late final List<String> _pathComponents;
  late final String _gsUrl;

  Reference._({
    required this.storage,
    required this.bucket,
    required String path,
  }) {
    _pathComponents = [
      ...path.split('/').where((element) => element.isNotEmpty),
    ];

    if (_pathComponents.isEmpty) {
      fullPath = '/';
      name = "";
      _gsUrl = 'gs://$bucket/';
    } else {
      fullPath = _pathComponents.join('/');
      name = _pathComponents.last;
      _gsUrl = 'gs://$bucket/$fullPath';
    }
  }

  Reference? get parent {
    if (_pathComponents.isEmpty) {
      return null;
    }

    return Reference._(
      bucket: bucket,
      path: [...List.from(_pathComponents)..removeLast()].join('/'),
      storage: storage,
    );
  }

  Reference get root {
    return Reference._(
      bucket: bucket,
      path: '/',
      storage: storage,
    );
  }

  Reference child(String path) {
    final sanitized = path.split('/').where((e) => e.isNotEmpty).join('/');

    return Reference._(
      bucket: bucket,
      path: '$fullPath/$sanitized',
      storage: storage,
    );
  }

  Future<void> delete() async {
    await storage._apiClient.delete(fullPath);
  }

  Future<String> getDownloadURL() async {
    final downloadUrl = await storage._apiClient.getDownloadURL(fullPath);
    return downloadUrl;
  }

  Future<FullMetadata> getMetadata() async {
    final json = await storage._apiClient.getMetadata(fullPath);
    return FullMetadata._fromJson(json);
  }

  Future<ListResult> list([ListOptions? options]) async {
    final json = await storage._apiClient.list(
      fullPath,
      options,
    );

    return ListResult._fromJson(storage, json);
  }

  Future<ListResult> listAll() async {
    try {
      ListResult result = await list();

      while (result.nextPageToken != null) {
        final options = ListOptions(pageToken: result.nextPageToken);
        final pageResult = await list(options);
        result = result._concat(pageResult);
      }

      return result;
    } on FirebaseStorageException {
      rethrow;
    } catch (e, stackTrace) {
      throw FirebaseStorageException._unknown(stackTrace);
    }
  }

  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    final metadata = await storage._apiClient.getMetadata(fullPath);
    final size = metadata['size'] as int;

    if (size > maxSize) {
      return null;
    }

    final uri = storage._apiClient._buildDownloadURL(metadata, fullPath);
    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        return res.bodyBytes;
      } else {
        throw FirebaseStorageException._fromHttpStatusCode(res.statusCode);
      }
    } on FirebaseStorageException {
      rethrow;
    } catch (e, stackTrace) {
      throw FirebaseStorageException._unknown(stackTrace);
    }
  }

  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    if (data.length <= _chunkedUploadBaseChunkSize) {
      return _MultipartUploadTask._(this, fullPath, data, metadata);
    } else {
      final source = BufferSource(data.buffer.asByteData());
      return _ChunkedUploadTask._(this, fullPath, source, metadata);
    }
  }

  UploadTask putFile(File file, [SettableMetadata? metadata]) {
    // TODO:
    throw UnimplementedError();
  }

  UploadTask putString(
    String string, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    Uint8List bytes;
    String? contentType = metadata?.contentType;

    switch (format) {
      case PutStringFormat.raw:
        bytes = Uint8List.fromList(utf8.encode(string));
        break;
      case PutStringFormat.base64:
        bytes = base64.decode(string);
        break;
      case PutStringFormat.base64Url:
        bytes = base64.decode(Uri.decodeFull(string));
        break;
      case PutStringFormat.dataUrl:
        final uri = Uri.dataFromString(string);
        final mime = uri.data!.mimeType;
        contentType = mime;
        bytes = uri.data!.contentAsBytes();
        break;
    }

    final newMetadata = SettableMetadata(
      contentType: contentType ?? 'text/plain',
      customMetadata: metadata?.customMetadata,
      cacheControl: metadata?.cacheControl,
      contentDisposition: metadata?.contentDisposition,
      contentEncoding: metadata?.contentEncoding,
      contentLanguage: metadata?.contentLanguage,
    );

    return putData(bytes, newMetadata);
  }

  // TODO:
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) {
    throw UnimplementedError();
  }

  // TODO:
  DownloadTask writeToFile(File file) {
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      other is Reference &&
      other.fullPath == fullPath &&
      other.storage == storage;

  @override
  int get hashCode => Object.hash(storage, fullPath);

  @override
  String toString() => _gsUrl;
}
