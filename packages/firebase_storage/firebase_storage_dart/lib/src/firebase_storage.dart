part of firebase_storage_dart;

class FirebaseStorage {
  FirebaseStorage._({required this.app, String? bucket}) {
    assert(bucket != null || app.options.storageBucket != null);

    final bucketName = bucket ??
        app.options.storageBucket ??
        '${app.options.appId}.appspot.com';

    this.bucket = 'gs://$bucketName';
  }

  final FirebaseApp app;

  late final String bucket;

  static FirebaseStorage get instance => instanceFor(app: Firebase.app());

  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    return FirebaseStorage._(app: app);
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
    // TODO:
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
