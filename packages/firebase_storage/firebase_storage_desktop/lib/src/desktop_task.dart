// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_desktop/src/desktop_firebase_storage.dart';
import 'package:firebase_storage_desktop/src/desktop_task_snapshot.dart';
import 'package:firebase_storage_desktop/src/utils/exceptions.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

/// Implementation for a [TaskPlatform].
///
/// Other implementations for specific tasks should extend this class.
class DesktopTask extends TaskPlatform {
  /// Creates a new [DesktopTask] with a given task.
  DesktopTask(
    this._handle,
    this.storage,
    String path,
    this._initialTask,
  ) : super() {
    // Keep reference to whether the initial "start" task has completed.
    _initialTaskCompleter = Completer<void>();
    _snapshot = DesktopTaskSnapshot(storage, TaskState.running, {
      'path': path,
      'bytesTransferred': 0,
      'totalBytes': 1,
    });
    _initialTask().then((_) {
      _initialTaskCompleter.complete();
    }).catchError((Object e, StackTrace stackTrace) {
      _initialTaskCompleter.completeError(e, stackTrace);
      _didComplete = true;
      _exception = e;
      _stackTrace = stackTrace;
      if (_completer != null) {
        catchFuturePlatformException(e, stackTrace)
            .catchError(_completer!.completeError);
      }
    });

    // Get the task stream.
    _stream = DesktopFirebaseStorage.taskObservers[_handle]!.stream
        as Stream<TaskSnapshotPlatform>;
    late StreamSubscription _subscription;

    // Listen for stream events.
    _subscription = _stream.listen((TaskSnapshotPlatform snapshot) async {
      if (_snapshot.state != TaskState.canceled) {
        _snapshot = snapshot;
      }

      // If the stream event is complete, trigger the
      // completer to resolve with the snapshot.
      if (snapshot.state == TaskState.success) {
        _didComplete = true;
        _completer?.complete(snapshot);
        await _subscription.cancel();
      }
    }, onError: (Object e, StackTrace stackTrace) {
      if (e is FirebaseException && e.code == 'canceled') {
        _snapshot = DesktopTaskSnapshot(storage, TaskState.canceled, {
          'path': path,
          'bytesTransferred': _snapshot.bytesTransferred,
          'totalBytes': _snapshot.totalBytes,
        });
      } else {
        _snapshot = DesktopTaskSnapshot(storage, TaskState.error, {
          'path': path,
          'bytesTransferred': _snapshot.bytesTransferred,
          'totalBytes': _snapshot.totalBytes,
        });
      }
      _didComplete = true;
      _exception = e;
      _stackTrace = stackTrace;
      if (_completer != null) {
        catchFuturePlatformException(e, stackTrace)
            .catchError(_completer!.completeError);
      }
    }, cancelOnError: true);
  }

  Object? _exception;

  late StackTrace _stackTrace;

  bool _didComplete = false;

  Completer<TaskSnapshotPlatform>? _completer;

  late Stream<TaskSnapshotPlatform> _stream;

  late Completer<void> _initialTaskCompleter;

  Future<void> Function() _initialTask;

  final int _handle;

  /// The [FirebaseStoragePlatform] used to create the task.
  final FirebaseStoragePlatform storage;

  late TaskSnapshotPlatform _snapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return DesktopFirebaseStorage.taskObservers[_handle]!.stream
        as Stream<TaskSnapshotPlatform>;
  }

  @override
  TaskSnapshotPlatform get snapshot => _snapshot;

  @override
  Future<TaskSnapshotPlatform> get onComplete async {
    if (_didComplete && _exception == null) {
      return Future.value(snapshot);
    } else if (_didComplete && _exception != null) {
      return catchFuturePlatformException(_exception!, _stackTrace);
    } else {
      _completer ??= Completer<TaskSnapshotPlatform>();
      return _completer!.future;
    }
  }

  @override
  Future<bool> pause() async {
    throw UnimplementedError('pause() is not implemented');
    // try {
    //   if (!_initialTaskCompleter.isCompleted) {
    //     await _initialTaskCompleter.future;
    //   }

    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>('Task#pause', <String, dynamic>{
    //     'handle': _handle,
    //   });

    //   bool success = data!['status'];
    //   if (success) {
    //     _snapshot = DesktopTaskSnapshot(storage, TaskState.paused,
    //         Map<String, dynamic>.from(data['snapshot']));
    //   }
    //   return success;
    // } catch (e, stack) {
    //   return catchFuturePlatformException<bool>(e, stack);
    // }
  }

  @override
  Future<bool> resume() async {
    throw UnimplementedError('resume() is not implemented');
    // try {
    //   if (!_initialTaskCompleter.isCompleted) {
    //     await _initialTaskCompleter.future;
    //   }

    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>('Task#resume', <String, dynamic>{
    //     'handle': _handle,
    //   });

    //   bool success = data!['status'];
    //   if (success) {
    //     _snapshot = DesktopTaskSnapshot(storage, TaskState.running,
    //         Map<String, dynamic>.from(data['snapshot']));
    //   }
    //   return success;
    // } catch (e, stack) {
    //   return catchFuturePlatformException<bool>(e, stack);
  }
}

@override
Future<bool> cancel() async {
  throw UnimplementedError('cancel() is not implemented');
  //   try {
  //     if (!_initialTaskCompleter.isCompleted) {
  //       await _initialTaskCompleter.future;
  //     }

  //     Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
  //         .invokeMapMethod<String, dynamic>('Task#cancel', <String, dynamic>{
  //       'handle': _handle,
  //     });

  //     bool success = data!['status'];
  //     if (success) {
  //       _snapshot = DesktopTaskSnapshot(storage, TaskState.canceled,
  //           Map<String, dynamic>.from(data['snapshot']));
  //     }
  //     return success;
  //   } catch (e, stack) {
  //     return catchFuturePlatformException<bool>(e, stack);
  //   }
  // }
}

/// Implementation for [putFile] tasks.
class DesktopPutFileTask extends DesktopTask {
  // ignore: public_member_api_docs
  DesktopPutFileTask(int handle, FirebaseStoragePlatform storage, String path,
      File file, SettableMetadata? metadata)
      : super(handle, storage, path,
            _getTask(handle, storage, path, file, metadata));

  static Future<void> Function() _getTask(
      int handle,
      FirebaseStoragePlatform storage,
      String path,
      File file,
      SettableMetadata? metadata) {
    throw UnimplementedError('_geTask is not implemented');
    // return () => DesktopFirebaseStorage.channel
    //         .invokeMethod<void>('Task#startPutFile', <String, dynamic>{
    //       'appName': storage.app.name,
    //       'maxOperationRetryTime': storage.maxOperationRetryTime,
    //       'maxUploadRetryTime': storage.maxUploadRetryTime,
    //       'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //       'bucket': storage.bucket,
    //       'host': storage.emulatorHost,
    //       'port': storage.emulatorPort,
    //       'handle': handle,
    //       'path': path,
    //       'filePath': file.absolute.path,
    //       'metadata': metadata?.asMap(),
    //     });
  }
}

/// Implementation for [putString] tasks.
class DesktopPutStringTask extends DesktopTask {
  // ignore: public_member_api_docs
  DesktopPutStringTask(int handle, FirebaseStoragePlatform storage, String path,
      String data, PutStringFormat format, SettableMetadata? metadata)
      : super(handle, storage, path,
            _getTask(handle, storage, path, data, format, metadata));

  static Future<void> Function() _getTask(
      int handle,
      FirebaseStoragePlatform storage,
      String path,
      String data,
      PutStringFormat format,
      SettableMetadata? metadata) {
    throw UnimplementedError('_geTask is not implemented');
    // return () => DesktopFirebaseStorage.channel
    //         .invokeMethod<void>('Task#startPutString', <String, dynamic>{
    //       'appName': storage.app.name,
    //       'bucket': storage.bucket,
    //       'maxOperationRetryTime': storage.maxOperationRetryTime,
    //       'maxUploadRetryTime': storage.maxUploadRetryTime,
    //       'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //       'host': storage.emulatorHost,
    //       'port': storage.emulatorPort,
    //       'handle': handle,
    //       'path': path,
    //       'data': data,
    //       'format': format.index,
    //       'metadata': metadata?.asMap(),
    //     });
  }
}

/// Implementation for [put] tasks.
class DesktopPutTask extends DesktopTask {
  // ignore: public_member_api_docs
  DesktopPutTask(int handle, FirebaseStoragePlatform storage, String path,
      Uint8List data, SettableMetadata? metadata)
      : super(handle, storage, path,
            _getTask(handle, storage, path, data, metadata));

  static Future<void> Function() _getTask(
      int handle,
      FirebaseStoragePlatform storage,
      String path,
      Uint8List data,
      SettableMetadata? metadata) {
    throw UnimplementedError('_geTask is not implemented');
    // return () => DesktopFirebaseStorage.channel
    //         .invokeMethod<void>('Task#startPutData', <String, dynamic>{
    //       'appName': storage.app.name,
    //       'bucket': storage.bucket,
    //       'maxOperationRetryTime': storage.maxOperationRetryTime,
    //       'maxUploadRetryTime': storage.maxUploadRetryTime,
    //       'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //       'host': storage.emulatorHost,
    //       'port': storage.emulatorPort,
    //       'handle': handle,
    //       'path': path,
    //       'data': data,
    //       'metadata': metadata?.asMap(),
    //     });
  }
}

/// Implementation for [writeToFile] tasks.
class DesktopDownloadTask extends DesktopTask {
  // ignore: public_member_api_docs
  DesktopDownloadTask(
      int handle, FirebaseStoragePlatform storage, String path, File file)
      : super(handle, storage, path, _getTask(handle, storage, path, file));

  static Future<void> Function() _getTask(
      int handle, FirebaseStoragePlatform storage, String path, File file) {
    throw UnimplementedError('_geTask is not implemented');
    // return () => DesktopFirebaseStorage.channel
    //         .invokeMethod<void>('Task#writeToFile', <String, dynamic>{
    //       'appName': storage.app.name,
    //       'maxOperationRetryTime': storage.maxOperationRetryTime,
    //       'maxUploadRetryTime': storage.maxUploadRetryTime,
    //       'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //       'host': storage.emulatorHost,
    //       'port': storage.emulatorPort,
    //       'bucket': storage.bucket,
    //       'handle': handle,
    //       'path': path,
    //       'filePath': file.path,
    //     });
  }
}
