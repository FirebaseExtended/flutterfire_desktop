part of firebase_storage_dart;

/// Represents a reference to a Google Cloud Storage object. Developers can
/// upload, download, and delete objects, as well as get/set object metadata.
class Reference {
  final FirebaseStorage storage;
  final String bucket;

  late final String fullPath;
  late final String name;

  late final List<String> _pathComponents;

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
    } else {
      fullPath = _pathComponents.join('/');
      name = _pathComponents.last;
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
    // TODO:
    throw UnimplementedError();
  }

  Future<FullMetadata> getMetadata() async {
    // TODO:
    throw UnimplementedError();
  }

  Future<ListResult> list([ListOptions? options]) async {
    final objects = await storage._apiClient.list(
      fullPath,
      options,
    );

    return ListResult._fromObjects(
      objects: objects,
      src: this,
    );
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
    // TODO:
    throw UnimplementedError();
  }

  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    // TODO:
    throw UnimplementedError();
  }

  UploadTask putBlob(dynamic blob, [SettableMetadata? metadata]) {
    // TODO:
    throw UnimplementedError();
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
  String toString() =>
      'Reference(app: ${storage.app.name}, fullPath: $fullPath)';
}
