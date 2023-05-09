// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;
import 'package:firebase_storage_desktop/src/desktop_reference.dart';
import 'package:firebase_storage_desktop/src/desktop_task_snapshot.dart';
import 'package:firebase_storage_desktop/src/utils/exceptions.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart'
    as storage_dart;
import 'package:flutter/services.dart';

/// Method Channel delegate for [FirebaseStoragePlatform].
class DesktopFirebaseStorage extends FirebaseStoragePlatform {
  /// Creates a new [DesktopFirebaseStorage] instance with an [app] and/or
  /// [bucket].
  DesktopFirebaseStorage({required FirebaseApp app, required String bucket})
      : _app = core_dart.Firebase.app(app.name),
        super(appInstance: app, bucket: bucket) {
    // The channel setMethodCallHandler callback is not app specific, so there
    // is no need to register the caller more than once.
    if (_initialized) return;

    _initialized = true;
  }

  /// Internal stub class initializer.
  ///
  /// When the user code calls an storage method, the real instance is
  /// then initialized via the [delegateFor] method.
  DesktopFirebaseStorage._()
      : _app = null,
        super(appInstance: null, bucket: '');

  /// Keep an internal reference to whether the [DesktopFirebaseStorage]
  /// class has already been initialized.
  static bool _initialized = false;

  /// Returns a unique key to identify the instance by [FirebaseApp] name and
  /// any custom storage buckets.
  static String _getInstanceKey(String /*!*/ appName, String bucket) {
    return '$appName|$bucket';
  }

  /// Instance of storage from Identity Provider API service.
  storage_dart.FirebaseStorage? get _delegate => _app == null
      ? null
      : storage_dart.FirebaseStorage.instanceFor(app: _app!);

  final core_dart.FirebaseApp? _app;

  static Map<String, DesktopFirebaseStorage> _desktopFirebaseStorageInstances =
      <String, DesktopFirebaseStorage>{};

  ///Method call handleer
  ///Todo need restructring
  Future<void> handleMethodCalls(MethodCall call) async {
    Map<dynamic, dynamic> arguments = call.arguments;

    switch (call.method) {
      case 'Task#onProgress':
        return _handleTaskStateChange(TaskState.running, arguments);
      case 'Task#onPaused':
        return _handleTaskStateChange(TaskState.paused, arguments);
      case 'Task#onSuccess':
        return _handleTaskStateChange(TaskState.success, arguments);
      case 'Task#onCanceled':
        return _sendTaskException(
            arguments['handle'],
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'canceled',
              message: 'User canceled the upload/download.',
            ));
      case 'Task#onFailure':
        Map<String, dynamic> errorMap =
            Map<String, dynamic>.from(arguments['error']);
        return _sendTaskException(
            arguments['handle'],
            FirebaseException(
              plugin: 'firebase_storage',
              code: errorMap['code'],
              message: errorMap['message'],
            ));
    }
  }

  /// Returns a stub instance to allow the platform interface to access
  /// the class instance statically.
  static DesktopFirebaseStorage get instance {
    return DesktopFirebaseStorage._();
  }

  static int _methodChannelHandleId = 0;

  /// Increments and returns the next channel ID handler for Storage.
  static int get nextDesktopHandleId => _methodChannelHandleId++;

  /// A map containing all Task stream observers, keyed by their handle.
  static final Map<int, StreamController<dynamic>> taskObservers =
      <int, StreamController<TaskSnapshotPlatform>>{};

  @override
  int maxOperationRetryTime = const Duration(minutes: 2).inMilliseconds;

  @override
  int maxUploadRetryTime = const Duration(minutes: 10).inMilliseconds;

  @override
  int maxDownloadRetryTime = const Duration(minutes: 10).inMilliseconds;

  Future<void> _handleTaskStateChange(
      TaskState taskState, Map<dynamic, dynamic> arguments) async {
    // Get & cast native snapshot data to a Map
    Map<String, dynamic> snapshotData =
        Map<String, dynamic>.from(arguments['snapshot']);

    // Get the cached Storage instance.
    FirebaseStoragePlatform storage = _desktopFirebaseStorageInstances[
        _getInstanceKey(arguments['appName'], arguments['bucket'])]!;

    // Create a snapshot.
    TaskSnapshotPlatform snapshot =
        DesktopTaskSnapshot(storage, taskState, snapshotData);

    // Fire a snapshot event.
    taskObservers[arguments['handle']]!.add(snapshot);
  }

  void _sendTaskException(int handle, FirebaseException exception) {
    taskObservers[handle]!.addError(exception);
  }

  @override
  FirebaseStoragePlatform delegateFor(
      {required FirebaseApp app, required String bucket}) {
    String key = _getInstanceKey(app.name, bucket);

    return _desktopFirebaseStorageInstances[key] ??=
        DesktopFirebaseStorage(app: app, bucket: bucket);
  }

  @override
  ReferencePlatform ref(String path) {
    return DesktopReference(this, path);
  }

  @override
  Future<void> useStorageEmulator(String host, int port) async {
    emulatorHost = host;
    emulatorPort = port;
    try {
      await _delegate!.useStorageEmulator(host: host, port: port);
      // await DesktopFirebaseStorage.channel
      //     .invokeMethod('Storage#useEmulator', <String, dynamic>{
      //   'appName': app.name,
      //   'maxOperationRetryTime': maxOperationRetryTime,
      //   'maxUploadRetryTime': maxUploadRetryTime,
      //   'maxDownloadRetryTime': maxDownloadRetryTime,
      //   'bucket': bucket,
      //   'host': emulatorHost,
      //   'port': emulatorPort
      // });
    } catch (e, s) {
      convertPlatformException(e, s);
    }
  }

  @override
  void setMaxOperationRetryTime(int time) {
    maxOperationRetryTime = time;
  }

  @override
  void setMaxUploadRetryTime(int time) {
    maxUploadRetryTime = time;
  }

  @override
  Future<void> setMaxDownloadRetryTime(int time) async {
    maxDownloadRetryTime = time;
  }
}
