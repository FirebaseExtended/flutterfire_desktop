part of firebase_storage_dart;

class FirebaseStorage {
  final FirebaseApp app;
  late final String bucket;

  late final String _bucketName;
  late final StorageApi _api;

  static Uri? _emulatorUri;

  FirebaseStorage._({required this.app, String? bucket}) {
    assert(bucket != null || app.options.storageBucket != null);
    final options = app.options;
    final storageBucket = options.storageBucket;
    final appId = options.appId;

    _bucketName = bucket ?? storageBucket ?? '$appId.appspot.com';
    this.bucket = 'gs://$_bucketName';

    _api = StorageApi(_bucketName, _emulatorUri);

    firebasePluginSubscribe(Topics.currentUser(app), (message) {
      final idToken = message['idToken'];
      _api._idToken = idToken;
    });
  }

  static FirebaseStorage get instance => instanceFor(app: Firebase.app());
  static final Map<FirebaseApp, FirebaseStorage> _instances = {};

  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    return _instances[app] ??= FirebaseStorage._(app: app);
  }

  int get maxOperationRetryTime {
    return _api.client.retryPolicy.maxOperationRetryTime;
  }

  int get maxUploadRetryTime {
    return _api.client.retryPolicy.maxUploadRetryTime;
  }

  int get maxDownloadRetryTime {
    return _api.client.retryPolicy.maxDownloadRetryTime;
  }

  void setMaxOperationRetryTime(int time) {
    _api.client.retryPolicy.maxOperationRetryTime = time;
  }

  void setMaxUploadRetryTime(int time) {
    _api.client.retryPolicy.maxUploadRetryTime = time;
  }

  void setMaxDownloadRetryTime(int time) {
    _api.client.retryPolicy.maxDownloadRetryTime = time;
  }

  Reference ref([String? path]) {
    return Reference._(
      bucket: _bucketName,
      path: path ?? '/',
      storage: this,
    );
  }

  Reference refFromURL(String url) {
    final uri = Uri.parse(url);

    if (uri.scheme != 'gs' || uri.scheme != 'https') {
      throw ArgumentError.value(
        url,
        'url',
        'The URL is not a valid Firebase Storage object URL.',
      );
    }

    return Reference._(
      bucket: uri.host.replaceAll('.appspot.com', ''),
      path: uri.path,
      storage: this,
    );
  }

  Future<void> useStorageEmulator(String host, int port) async {
    _emulatorUri = _api.useEmulator(host, port);
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
