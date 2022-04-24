library firebase_storage_desktop;

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;

class FirebaseStorageDesktop extends FirebaseStoragePlatform {
  FirebaseStorageDesktop({required FirebaseApp app, required String bucket})
      : _app = core_dart.Firebase.app(app.name),
        super(appInstance: app, bucket: bucket);

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  ///
  // ignore: prefer_constructors_over_static_methods
  static FirebaseStorageDesktop get instance {
    return FirebaseStorageDesktop.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp] and/or custom storage bucket.
  ///
  /// If [app] is not provided, the default Firebase app will be used.
  /// If [bucket] is not provided, the default storage bucket will be used.
  static FirebaseStorageDesktop instanceFor({
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

    FirebaseStorageDesktop newInstance =
        FirebaseStorageDesktop(app: app, bucket: _bucket);
    _cachedInstances[key] = newInstance;

    return newInstance;
  }

  static final Map<String, FirebaseStorageDesktop> _cachedInstances = {};
  final core_dart.FirebaseApp? _app;
  FirebaseStoragePlatform? _delegatePackingProperty;
  FirebaseStoragePlatform get _delegate {
    return _delegatePackingProperty ??= FirebaseStoragePlatform.instanceFor(
      app: app,
      bucket: bucket,
    );
  }

  /// The maximum time to retry operations other than uploads or downloads in milliseconds.
  @override
  int get maxOperationRetryTime {
    return _delegate.maxOperationRetryTime;
  }

  /// The maximum time to retry uploads in milliseconds.
  @override
  int get maxUploadRetryTime {
    return _delegate.maxUploadRetryTime;
  }

  /// The maximum time to retry downloads in milliseconds.
  @override
  int get maxDownloadRetryTime {
    return _delegate.maxDownloadRetryTime;
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance is required by the user.
  @override
  FirebaseStoragePlatform delegateFor(
      {required FirebaseApp app, required String bucket}) {
    if (app.options.storageBucket == null) {
      if (app.name == defaultFirebaseAppName) {
        _throwNoBucketError(
            'No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.');
      } else {
        _throwNoBucketError(
            "No storage bucket could be found for the app '${app.name}'. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.");
      }
    }

    String _bucket = bucket;

    // Previous versions allow storage buckets starting with "gs://".
    // Since we need to create a key using the bucket, it must not include "gs://"
    // since native does not include it when requesting the bucket. This keeps
    // the code backwards compatible but also works with the refactor.
    if (bucket.startsWith('gs://')) {
      _bucket = _bucket.replaceFirst('gs://', '');
    }

    String key = '${app.name}|$_bucket';
    if (_cachedInstances.containsKey(key)) {
      return _cachedInstances[key]!;
    }

    FirebaseStorageDesktop newInstance =
        FirebaseStorageDesktop(app: app, bucket: _bucket);
    _cachedInstances[key] = newInstance;

    return newInstance;
  }

  /// Returns a reference for the given path in the default bucket.
  ///
  /// [path] A relative path to initialize the reference with, for example
  ///   `path/to/image.jpg`. If not passed, the returned reference points to
  ///   the bucket root.
  @override
  ReferencePlatform ref(String path) {
    throw UnimplementedError('ref() is not implemented');
  }

  /// Changes this instance to point to a Storage emulator running locally.
  ///
  /// Set the [host] (ex: localhost) and [port] (ex: 9199) of the local emulator.
  ///
  /// Note: Must be called immediately, prior to accessing storage methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  ///
  /// Note: storage emulator is not supported for web yet. firebase-js-sdk does not support
  /// storage.useStorageEmulator until v9
  @override
  Future<void> useStorageEmulator(String host, int port) {
    throw UnimplementedError('useStorageEmulator() is not implemented');
  }

  /// The new maximum operation retry time in milliseconds.
  @override
  void setMaxOperationRetryTime(int time) {
    assert(!time.isNegative);
    return _delegate.setMaxOperationRetryTime(time);
  }

  /// The new maximum upload retry time in milliseconds.
  @override
  void setMaxUploadRetryTime(int time) {
    assert(!time.isNegative);
    return _delegate.setMaxUploadRetryTime(time);
  }

  /// The new maximum download retry time in milliseconds.
  @override
  void setMaxDownloadRetryTime(int time) {
    assert(!time.isNegative);
    return _delegate.setMaxDownloadRetryTime(time);
  }
}

void _throwNoBucketError(String message) {
  throw FirebaseException(
      plugin: 'firebase_storage', code: 'no-bucket', message: message);
}
