import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_dart/firebase_storage_dart.dart'
    as storage_dart;
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import 'list_result_desktop.dart';
import 'task_desktop.dart';

storage_dart.SettableMetadata? toDartSettableMetadata(
  SettableMetadata? metadata,
) {
  if (metadata == null) {
    return null;
  }

  return storage_dart.SettableMetadata(
    cacheControl: metadata.cacheControl,
    contentDisposition: metadata.contentDisposition,
    contentEncoding: metadata.contentEncoding,
    contentLanguage: metadata.contentLanguage,
    contentType: metadata.contentType,
    customMetadata: metadata.customMetadata,
  );
}

class ReferenceDesktop extends ReferencePlatform {
  final storage_dart.Reference _delegate;

  ReferenceDesktop(
      storage_dart.FirebaseStorage storageDelegate, super.storage, super.path)
      : _delegate = storageDelegate.ref(path);

  @override
  Future<void> delete() {
    return _delegate.delete();
  }

  @override
  Future<String> getDownloadURL() {
    return _delegate.getDownloadURL();
  }

  @override
  Future<FullMetadata> getMetadata() async {
    final dartMetadata = await _delegate.getMetadata();
    final json = dartMetadata.asMap();
    return FullMetadata(json);
  }

  @override
  Future<ListResultPlatform> list([ListOptions? options]) async {
    storage_dart.ListOptions? opts;

    if (options != null) {
      opts = storage_dart.ListOptions(
        maxResults: options.maxResults,
        pageToken: options.pageToken,
      );
    }

    final dartResult = await _delegate.list(opts);
    return ListResultDesktop(dartResult, storage, dartResult.nextPageToken);
  }

  @override
  Future<ListResultPlatform> listAll() async {
    final dartResult = await _delegate.listAll();
    return ListResultDesktop(dartResult, storage, null);
  }

  @override
  Future<Uint8List?> getData(int maxSize) {
    return _delegate.getData(maxSize);
  }

  @override
  TaskPlatform putData(Uint8List data, [SettableMetadata? metadata]) {
    final dartSettableMeta = toDartSettableMetadata(metadata);
    final dartTask = _delegate.putData(data, dartSettableMeta);

    return TaskDesktop(dartTask, storage);
  }

  @override
  TaskPlatform putBlob(data, [SettableMetadata? metadata]) {
    throw UnsupportedError('putBlob() is only supported on web');
  }

  @override
  TaskPlatform putFile(File file, [SettableMetadata? metadata]) {
    final dartSettableMeta = toDartSettableMetadata(metadata);
    final dartTask = _delegate.putFile(file, dartSettableMeta);

    return TaskDesktop(dartTask, storage);
  }

  @override
  TaskPlatform putString(
    String data,
    PutStringFormat format, [
    SettableMetadata? metadata,
  ]) {
    final dartSettableMeta = toDartSettableMetadata(metadata);
    storage_dart.PutStringFormat dartFormat;

    switch (format) {
      case PutStringFormat.raw:
        dartFormat = storage_dart.PutStringFormat.raw;
        break;
      case PutStringFormat.base64:
        dartFormat = storage_dart.PutStringFormat.base64;
        break;
      case PutStringFormat.base64Url:
        dartFormat = storage_dart.PutStringFormat.base64Url;
        break;
      case PutStringFormat.dataUrl:
        dartFormat = storage_dart.PutStringFormat.dataUrl;
        break;
    }

    final dartTask = _delegate.putString(
      data,
      format: dartFormat,
      metadata: dartSettableMeta,
    );

    return TaskDesktop(dartTask, storage);
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    final dartSettableMeta = toDartSettableMetadata(metadata)!;
    final dartMetadata = await _delegate.updateMetadata(dartSettableMeta);

    return FullMetadata(dartMetadata.asMap());
  }

  @override
  TaskPlatform writeToFile(File file) {
    final dartTask = _delegate.writeToFile(file);
    return TaskDesktop(dartTask, storage);
  }
}
