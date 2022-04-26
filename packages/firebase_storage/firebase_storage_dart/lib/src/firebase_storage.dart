// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

part of firebase_storage_dart;

/// Pure Dart FirebaseAuth implementation.
/// The entrypoint for [FirebaseStorage].
class FirebaseStorage {
  /// Creates Firebase Functions
  // @visibleForTesting
  FirebaseStorage({required this.app, required this.bucket}) {
    _api = API.instanceOf(
      APIConfig(
        app.options.apiKey,
        app.options.projectId,
      ),
    );
  }

  /// The [FirebaseApp] for this current [FirebaseStorage] instance.
  FirebaseApp app;

  /// Initialized [API] instance linked to this instance.
  late final API _api;

  /// Change the HTTP client for the purpose of testing.
  @visibleForTesting
  // ignore: avoid_setters_without_getters
  set client(http.Client client) {
    _api.client = client;
  }

  /// The storage bucket of this instance.
  String bucket;

  // Same default as the method channel implementation
  int _maxDownloadRetryTime = const Duration(minutes: 10).inMilliseconds;

  // Same default as the method channel implementation
  int _maxOperationRetryTime = const Duration(minutes: 2).inMilliseconds;
  // Same default as the method channel implementation
  int _maxUploadRetryTime = const Duration(minutes: 10).inMilliseconds;

  static final Map<String, FirebaseStorage> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseStorage get instance {
    return FirebaseStorage.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp] and/or custom storage bucket.
  ///
  /// If [app] is not provided, the default Firebase app will be used.
  /// If [bucket] is not provided, the default storage bucket will be used.
  static FirebaseStorage instanceFor({
    FirebaseApp? app,
    String? bucket,
  }) {
    app ??= Firebase.app();

    if (bucket == null && app.options.storageBucket == null) {
      if (app.name == defaultFirebaseAppName) {
        _throwNoBucketError(
            'No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.');
      } else {
        _throwNoBucketError(
            "No storage bucket could be found for the app '${app.name}'. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.");
      }
    }

    String _bucket = bucket ?? app.options.storageBucket!;

    // Previous versions allow storage buckets starting with "gs://".
    // Since we need to create a key using the bucket, it must not include "gs://"
    // since native does not include it when requesting the bucket. This keeps
    // the code backwards compatible but also works with the refactor.
    if (_bucket.startsWith('gs://')) {
      _bucket = _bucket.replaceFirst('gs://', '');
    }

    String key = '${app.name}|$_bucket';
    if (_cachedInstances.containsKey(key)) {
      return _cachedInstances[key]!;
    }

    FirebaseStorage newInstance = FirebaseStorage(app: app, bucket: _bucket);
    _cachedInstances[key] = newInstance;

    return newInstance;
  }

  /// The Storage emulator host this instance is configured to use. This
  /// was required since iOS does not persist these settings on instances and
  /// they need to be set every time when getting a `FIRStorage` instance.
  String? emulatorHost;

  /// The Storage emulator port this instance is configured to use. This
  /// was required since iOS does not persist these settings on instances and
  /// they need to be set every time when getting a `FIRStorage` instance.
  int? emulatorPort;

  /// Returns a new [Reference].
  ///
  /// If the [path] is empty, the reference will point to the root of the
  /// storage bucket.
  Reference ref([String? path]) {
    path ??= '/';
    return Reference.fromPath(storage: this, path: path);
  }

  /// Returns a new [Reference] from a given URL.
  ///
  /// The [url] can either be a HTTP or Google Storage URL pointing to an object.
  /// If the URL contains a storage bucket which is different to the current
  /// [FirebaseStorage.bucket], a new [FirebaseStorage] instance for the
  /// [Reference] will be used instead.
  Reference refFromURL(String url) {
    assert(url.startsWith('gs://') || url.startsWith('http'),
        "'a url must start with 'gs://' or 'https://'");

    String? bucket;
    String? path;

    if (url.startsWith('http')) {
      final parts = partsFromHttpUrl(url);

      assert(parts != null,
          "url could not be parsed, ensure it's a valid storage url");

      bucket = parts!['bucket'];
      path = parts['path'];
    } else {
      bucket = bucketFromGoogleStorageUrl(url);
      path = pathFromGoogleStorageUrl(url);
    }

    return FirebaseStorage.instanceFor(app: app, bucket: 'gs://$bucket')
        .ref(path);
  }

  /// The maximum time to retry operations other than uploads or downloads in milliseconds.
  int get maxOperationRetryTime {
    return _maxOperationRetryTime;
  }

  /// The maximum time to retry uploads in milliseconds.
  int get maxUploadRetryTime {
    return _maxUploadRetryTime;
  }

  /// The maximum time to retry downloads in milliseconds.
  int get maxDownloadRetryTime {
    return _maxDownloadRetryTime;
  }

  /// Sets the new maximum operation retry time.
  void setMaxOperationRetryTime(int time) {
    assert(!time.isNegative);
    _maxOperationRetryTime = time;
  }

  /// Sets the new maximum upload retry time.
  void setMaxUploadRetryTime(int time) {
    assert(!time.isNegative);
    _maxUploadRetryTime = time;
  }

  /// Sets the new maximum download retry time.
  void setMaxDownloadRetryTime(int time) {
    assert(!time.isNegative);
    _maxDownloadRetryTime = time;
  }

  /// Changes this instance to point to a Storage emulator running locally.
  ///
  /// Set the [host] (ex: localhost) and [port] (ex: 9199) of the local emulator.
  ///
  /// Note: Must be called immediately, prior to accessing storage methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  @Deprecated(
    'Will be removed in future release. '
    'Use useStorageEmulator().',
  )
  Future<void> useEmulator({required String host, required int port}) async {
    assert(host.isNotEmpty);
    assert(!port.isNegative);

    await useStorageEmulator(host: host, port: port);
  }

  /// Changes this instance to point to a Storage emulator running locally.
  ///
  /// Set the [host] of the local emulator, such as "localhost"
  /// Set the [port] of the local emulator, such as "9199" (port 9199 is default for storage package)
  ///
  /// Note: Must be called immediately, prior to accessing storage methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  Future<Map> useStorageEmulator(
      {String host = 'localhost', int port = 9199}) async {
    assert(host.isNotEmpty);
    assert(!port.isNegative);

    try {
      return await _api.emulator.useEmulator(host, port);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String toString() => '$FirebaseStorage(app: ${app.name}, bucket: $bucket)';
}

void _throwNoBucketError(String message) {
  throw FirebaseException(
      plugin: 'firebase_storage', code: 'no-bucket', message: message);
}
