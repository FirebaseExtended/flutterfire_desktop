part of firebase_storage_dart;

class FirebaseStorage {
  final FirebaseApp app;
  late final String _bucketName;
  String get bucket => 'gs://$_bucketName';

  late StorageApiClient _apiClient;

  FirebaseStorage._({required this.app, String? bucket}) {
    assert(bucket != null || app.options.storageBucket != null);

    final bucketName = bucket ??
        app.options.storageBucket ??
        '${app.options.appId}.appspot.com';

    _bucketName = bucketName;
    _apiClient = StorageApiClient(clientViaApiKey(app.options.apiKey));
  }

  static FirebaseStorage get instance => instanceFor(app: Firebase.app());

  static final Map<FirebaseApp, FirebaseStorage> _instances = {};

  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    return _instances[app] ??= FirebaseStorage._(app: app);
  }

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
    final uri = Uri(
      scheme: 'http',
      host: host,
      port: port,
    );

    _apiClient = _apiClient.withServiceUri(uri);
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
