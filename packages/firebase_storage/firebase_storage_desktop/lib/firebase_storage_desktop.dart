library firebase_storage_desktop;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;
import 'package:firebase_storage_dart/firebase_storage_dart.dart'
    as storage_dart;

part 'src/error.dart';
part 'src/list_result_desktop.dart';
part 'src/reference_desktop.dart';
part 'src/task_desktop.dart';
part 'src/task_snapshot_desktop.dart';

class FirebaseStorageDesktop extends FirebaseStoragePlatform {
  final core_dart.FirebaseApp? _app;

  FirebaseStorageDesktop({FirebaseApp? app, String? bucket})
      : _app = app == null ? null : core_dart.Firebase.app(app.name),
        super(bucket: bucket ?? '');

  static void registerWith() {
    FirebaseStoragePlatform.instance = FirebaseStorageDesktop.instance;
  }

  static FirebaseStorageDesktop get instance => FirebaseStorageDesktop();

  storage_dart.FirebaseStorage get _delegate {
    if (_app == null) {
      return storage_dart.FirebaseStorage.instance;
    }

    return storage_dart.FirebaseStorage.instanceFor(app: _app!);
  }

  @override
  int get maxOperationRetryTime => _delegate.maxOperationRetryTime;

  @override
  int get maxDownloadRetryTime => _delegate.maxDownloadRetryTime;

  @override
  int get maxUploadRetryTime => _delegate.maxUploadRetryTime;

  @override
  FirebaseStoragePlatform delegateFor({
    required FirebaseApp app,
    required String bucket,
  }) {
    return FirebaseStorageDesktop(app: app, bucket: bucket);
  }

  @override
  ReferencePlatform ref(String path) => ReferenceDesktop(_delegate, this, path);

  @override
  Future<void> useStorageEmulator(String host, int port) {
    return _delegate.useStorageEmulator(host, port);
  }

  @override
  void setMaxDownloadRetryTime(int time) {
    _delegate.setMaxDownloadRetryTime(time);
  }

  @override
  void setMaxOperationRetryTime(int time) {
    _delegate.setMaxOperationRetryTime(time);
  }

  @override
  void setMaxUploadRetryTime(int time) {
    _delegate.setMaxUploadRetryTime(time);
  }
}
