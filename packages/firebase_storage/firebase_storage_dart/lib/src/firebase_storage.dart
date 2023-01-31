part of firebase_storage_dart;

class FirebaseStorage {
  final FirebaseApp app;
  late final String bucket;

  late final String _bucketName;
  late final StorageApiClient _apiClient;

  static Uri? _emulatorUri;

  Duration _maxOperationRetryTime = const Duration(minutes: 2);
  Duration _maxUploadRetryTime = const Duration(minutes: 10);
  Duration _maxDownloadRetryTime = const Duration(minutes: 10);

  FirebaseStorage._({required this.app, String? bucket}) {
    assert(bucket != null || app.options.storageBucket != null);
    final options = app.options;
    final storageBucket = options.storageBucket;
    final appId = options.appId;

    _bucketName = bucket ?? storageBucket ?? '$appId.appspot.com';
    this.bucket = 'gs://$_bucketName';

    _apiClient = StorageApiClient(_bucketName, _emulatorUri);

    firebasePluginSubscribe(Topics.currentUser(app), (message) {
      final idToken = message['idToken'];
      _apiClient._idToken = idToken;
    });
  }

  static FirebaseStorage get instance => instanceFor(app: Firebase.app());
  static final Map<FirebaseApp, FirebaseStorage> _instances = {};

  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    return _instances[app] ??= FirebaseStorage._(app: app);
  }

  Duration get maxOperationRetryTime {
    return _maxOperationRetryTime;
  }

  Duration get maxUploadRetryTime {
    return _maxUploadRetryTime;
  }

  Duration get maxDownloadRetryTime {
    return _maxDownloadRetryTime;
  }

  void setMaxOperationRetryTime(Duration time) {
    _maxOperationRetryTime = time;
  }

  void setMaxUploadRetryTime(Duration time) {
    _maxUploadRetryTime = time;
  }

  void setMaxDownloadRetryTime(Duration time) {
    _maxDownloadRetryTime = time;
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
    _emulatorUri = _apiClient.useEmulator(host, port);
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
