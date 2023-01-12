part of firebase_storage_dart;

class FirebaseStorage {
  final FirebaseApp app;
  late final String bucket;

  late StorageApiClient _apiClient;

  FirebaseStorage._({required this.app, String? bucket}) {
    assert(bucket != null || app.options.storageBucket != null);
    final options = app.options;

    final bucketName =
        bucket ?? options.storageBucket ?? '${options.appId}.appspot.com';

    this.bucket = 'gs://$bucketName';

    _apiClient = StorageApiClient(
      bucketName,
      clientViaApiKey(app.options.apiKey),
    );

    if (_emulatorUri != null) {
      _apiClient = _apiClient.withServiceUri(_emulatorUri!);
    }
  }

  static FirebaseStorage get instance => instanceFor(app: Firebase.app());

  static final Map<FirebaseApp, FirebaseStorage> _instances = {};

  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    return _instances[app] ??= FirebaseStorage._(app: app);
  }

  static Uri? _emulatorUri;

  Reference ref([String? path]) {
    path ??= '/';

    return Reference._(
      bucket: bucket,
      path: path,
      storage: this,
    );
  }

  Reference refFromURL(String url) {
    // TODO:
    throw UnimplementedError();
  }

  Future<void> useStorageEmulator(String host, int port) async {
    _emulatorUri = Uri(
      scheme: 'http',
      host: host,
      port: port,
    );

    _apiClient = _apiClient.withServiceUri(_emulatorUri!);
  }

  Duration get maxOperationRetryTime {
    throw UnimplementedError();
  }

  Duration get maxUploadRetryTime {
    throw UnimplementedError();
  }

  Duration get maxDownloadRetryTime {
    throw UnimplementedError();
  }

  void setMaxOperationRetryTime(Duration time) {
    // TODO:
  }

  void setMaxUploadRetryTime(Duration time) {
    // TODO:
  }

  void setMaxDownloadRetryTime(Duration time) {
    // TODO:
  }

  @override
  bool operator ==(Object other) =>
      other is FirebaseStorage &&
      other.app.name == app.name &&
      other.bucket == bucket;

  @override
  int get hashCode => Object.hash(app.name, bucket);

  @override
  String toString() => '$FirebaseStorage(app: ${app.name}, bucket: $bucket)';
}
