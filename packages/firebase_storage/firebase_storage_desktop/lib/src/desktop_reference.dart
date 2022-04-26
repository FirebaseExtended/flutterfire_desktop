// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_desktop/src/desktop_firebase_storage.dart';
import 'package:firebase_storage_desktop/src/desktop_list_result.dart';
import 'package:firebase_storage_desktop/src/desktop_task.dart';
import 'package:firebase_storage_desktop/src/utils/exceptions.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

/// An implementation of [ReferencePlatform] that uses [Desktop] to
/// communicate with Firebase plugins.
class DesktopReference extends ReferencePlatform {
  /// Creates a [ReferencePlatform] that is implemented using [Desktop].
  DesktopReference(FirebaseStoragePlatform storage, String path)
      : super(storage, path);

  @override
  Future<void> delete() async {
    throw UnimplementedError('delete() is not implemented');
    // try {
    //   await DesktopFirebaseStorage.channel
    //       .invokeMethod('Reference#delete', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //   });
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  Future<String> getDownloadURL() async {
    throw UnimplementedError('getDownloadURL() is not implemented');
    // try {
    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>(
    //           'Reference#getDownloadURL', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //   });

    //   return data!['downloadURL'];
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  Future<FullMetadata> getMetadata() async {
    throw UnimplementedError('getMetadata() is not implemented');
    // try {
    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>(
    //           'Reference#getMetadata', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //   });

    //   return FullMetadata(data!);
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  Future<ListResultPlatform> list([ListOptions? options]) async {
    throw UnimplementedError('getMetadata() is not implemented');
    // try {
    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>('Reference#list', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //     'options': <String, dynamic>{
    //       'maxResults': options?.maxResults ?? 1000,
    //       'pageToken': options?.pageToken,
    //     },
    //   });

    //   return DesktopListResult(
    //     storage,
    //     nextPageToken: data!['nextPageToken'],
    //     items: List.from(data['items']),
    //     prefixes: List.from(data['prefixes']),
    //   );
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  Future<ListResultPlatform> listAll() async {
    throw UnimplementedError('listAll() is not implemented');
    // try {
    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>(
    //           'Reference#listAll', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //   });
    //   return DesktopListResult(
    //     storage,
    //     nextPageToken: data!['nextPageToken'],
    //     items: List.from(data['items']),
    //     prefixes: List.from(data['prefixes']),
    //   );
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  Future<Uint8List?> getData(int maxSize) {
    throw UnimplementedError('getData(int maxSize) is not implemented');
    // try {
    //   return DesktopFirebaseStorage.channel
    //       .invokeMethod<Uint8List>('Reference#getData', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //     'maxSize': maxSize,
    //   });
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  TaskPlatform putData(Uint8List data, [SettableMetadata? metadata]) {
    int handle = DesktopFirebaseStorage.nextDesktopHandleId;
    DesktopFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return DesktopPutTask(handle, storage, fullPath, data, metadata);
  }

  @override
  TaskPlatform putBlob(dynamic data, [SettableMetadata? metadata]) {
    throw UnimplementedError(
        'putBlob() is not supported on native platforms. Use [put], [putFile] or [putString] instead.');
  }

  @override
  TaskPlatform putFile(File file, [SettableMetadata? metadata]) {
    int handle = DesktopFirebaseStorage.nextDesktopHandleId;
    DesktopFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return DesktopPutFileTask(handle, storage, fullPath, file, metadata);
  }

  @override
  TaskPlatform putString(String data, PutStringFormat format,
      [SettableMetadata? metadata]) {
    int handle = DesktopFirebaseStorage.nextDesktopHandleId;
    DesktopFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return DesktopPutStringTask(
        handle, storage, fullPath, data, format, metadata);
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    throw UnimplementedError(
        'updateMetadata(SettableMetadata metadata) is not implemented');
    // try {
    //   Map<String, dynamic>? data = await DesktopFirebaseStorage.channel
    //       .invokeMapMethod<String, dynamic>(
    //           'Reference#updateMetadata', <String, dynamic>{
    //     'appName': storage.app.name,
    //     'maxOperationRetryTime': storage.maxOperationRetryTime,
    //     'maxUploadRetryTime': storage.maxUploadRetryTime,
    //     'maxDownloadRetryTime': storage.maxDownloadRetryTime,
    //     'bucket': storage.bucket,
    //     'host': storage.emulatorHost,
    //     'port': storage.emulatorPort,
    //     'path': fullPath,
    //     'metadata': metadata.asMap(),
    //   });

    //   return FullMetadata(data!);
    // } catch (e, stack) {
    //   convertPlatformException(e, stack);
    // }
  }

  @override
  TaskPlatform writeToFile(File file) {
    int handle = DesktopFirebaseStorage.nextDesktopHandleId;
    DesktopFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return DesktopDownloadTask(handle, storage, fullPath, file);
  }
}
