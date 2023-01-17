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
    ListResult result = await list();

    while (result.nextPageToken != null) {
      final options = ListOptions(pageToken: result.nextPageToken);
      final pageResult = await list(options);
      result = result._concat(pageResult);
    }

    return result;
  }

  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    final metadata = await storage._apiClient.getMetadata(fullPath);
    final size = metadata['size'] as int;

    if (size > maxSize) {
      return null;
    }

    final uri = storage._apiClient._buildDownloadURL(metadata, fullPath);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return res.bodyBytes;
    } else {
      // TODO:
      throw Exception();
    }
  }

  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    if (data.length <= _resumableUploadBaseChunkSize) {
      return MultipartUploadTask._(storage, fullPath, data, metadata);
    } else {
      // TODO:
      throw UnimplementedError();
    }
  }

  UploadTask putBlob(dynamic blob, [SettableMetadata? metadata]) {
    throw UnimplementedError(
      'putBlob() is not supported on native platforms.'
      'Use putData, putFile or putString instead.',
    );
  }

  UploadTask putFile(File file, [SettableMetadata? metadata]) {
    // TODO:
    throw UnimplementedError();
  }

  UploadTask putString(
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    // TODO:
    throw UnimplementedError();
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
