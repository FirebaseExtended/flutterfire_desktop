// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A class representing an on-going storage task that additionally delegates to a [Future].
abstract class Task implements Future<TaskSnapshot> {
  /// The [FirebaseStorage] instance associated with this task.
  FirebaseStorage get storage;

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// await this [Task] directly.
  Stream<TaskSnapshot> get snapshotEvents;

  /// The latest [TaskSnapshot] for this task.
  TaskSnapshot get snapshot;

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.
  Future<bool> pause();

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.running]
  /// state.
  Future<bool> resume();

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the delegating task Future
  /// and stream ([snapshotEvents]) will trigger an error with a [FirebaseException].
  Future<bool> cancel();

  @override
  Stream<TaskSnapshot> asStream();

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  });

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot) onValue, {
    Function? onError,
  });

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action);

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  });
}

const _uploadChunkMaxSize = 32 * 1024 * 1024;
const _chunkedUploadBaseChunkSize = 256 * 1024;

/// A class which indicates an on-going upload task.
abstract class UploadTask extends Task implements Future<TaskSnapshot> {}

/// A class which indicates an on-going download task.
abstract class DownloadTask extends Task implements Future<TaskSnapshot> {}

class _MultipartUploadTask implements UploadTask {
  final Reference ref;
  final Uint8List data;
  final SettableMetadata? metadata;
  final String fullPath;

  @override
  late TaskSnapshot snapshot;

  @override
  FirebaseStorage get storage => ref.storage;

  late Completer<TaskSnapshot> _completer;

  _MultipartUploadTask._(
    this.ref,
    this.fullPath,
    this.data, [
    this.metadata,
  ]) {
    _completer = Completer<TaskSnapshot>();
    _upload();
  }

  @override
  Stream<TaskSnapshot> asStream() {
    return _completer.future.asStream();
  }

  @override
  Future<bool> cancel() async {
    return false;
  }

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _completer.future.catchError(onError, test: test);
  }

  @override
  Future<bool> pause() async {
    return false;
  }

  @override
  Future<bool> resume() async {
    return false;
  }

  @override
  Stream<TaskSnapshot> get snapshotEvents => asStream();

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot p1) onValue, {
    Function? onError,
  }) {
    return _completer.future.then(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) {
    return _completer.future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) {
    return _completer.future.whenComplete(action);
  }

  Future<void> _upload() async {
    try {
      await storage._apiClient.uploadMultipart(fullPath, data, metadata);

      final snapshot = TaskSnapshot._(
        ref: ref,
        bytesTransferred: data.length,
        totalBytes: data.length,
        state: TaskState.success,
      );

      _completer.complete(snapshot);
    } catch (error) {
      _completer.completeError(error);
    }
  }
}

class _ChunkedUploadTask extends UploadTask {
  final _controller = StreamController<TaskSnapshot>.broadcast();
  late final _subscription = _controller.stream.listen(
    _onSnapshot,
    onDone: _onDone,
    onError: _onError,
    cancelOnError: true,
  );

  final Completer<TaskSnapshot> _completer = Completer<TaskSnapshot>();

  final Reference _ref;
  final Source _source;
  final String _fullPath;
  final SettableMetadata? _metadata;

  late TaskSnapshot _snapshot;
  late String _uploadId;
  int _offset = 0;
  int _chunkSize = _chunkedUploadBaseChunkSize;

  @override
  TaskSnapshot get snapshot => _snapshot;

  set _currentSnapshot(TaskSnapshot value) {
    _snapshot = value;
    _controller.add(value);
  }

  _ChunkedUploadTask._(
    this._ref,
    this._fullPath,
    this._source, [
    this._metadata,
  ]) {
    _startUpload();
  }

  @override
  Stream<TaskSnapshot> asStream() {
    return _completer.future.asStream();
  }

  @override
  Future<bool> cancel() async {
    if (snapshot.state == TaskState.canceled) {
      return false;
    }

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.bytesTransferred,
      totalBytes: snapshot.totalBytes,
      state: TaskState.canceled,
    );

    return true;
  }

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _completer.future.catchError(onError, test: test);
  }

  @override
  Future<bool> pause() {
    if (snapshot.state == TaskState.paused) {
      return Future.value(false);
    }

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.bytesTransferred,
      totalBytes: snapshot.totalBytes,
      state: TaskState.paused,
    );

    return Future.value(true);
  }

  @override
  Future<bool> resume() {
    if (snapshot.state == TaskState.running ||
        snapshot.state == TaskState.success ||
        snapshot.state == TaskState.error ||
        snapshot.state == TaskState.canceled) {
      return Future.value(false);
    }

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.bytesTransferred,
      totalBytes: snapshot.totalBytes,
      state: TaskState.running,
    );

    return Future.value(true);
  }

  @override
  Stream<TaskSnapshot> get snapshotEvents => _controller.stream;

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot p1) onValue, {
    Function? onError,
  }) {
    return _completer.future.then(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) {
    return _completer.future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) {
    return _completer.future.whenComplete(action);
  }

  void _startUpload() {
    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: 0,
      totalBytes: _source.getTotalSize(),
      state: TaskState.running,
    );
  }

  void _onSnapshot(TaskSnapshot snapshot) {
    switch (snapshot.state) {
      case TaskState.error:
      case TaskState.success:
        _subscription.cancel();
        _controller.close();
        break;

      case TaskState.canceled:
        final errorCode = StorageErrorCode.canceled;
        _controller.addError(errorCode);
        break;

      case TaskState.paused:
        // TODO:
        break;

      case TaskState.running:
        _handleRunning(snapshot);
        break;
    }
  }

  void _onDone() {
    if (!_completer.isCompleted) {
      _completer.complete(snapshot);
    }
  }

  void _onError(error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }

  void _handleRunning(TaskSnapshot snapshot) {
    if (snapshot.bytesTransferred == 0) {
      _ref.storage._apiClient
          .startChunkedUpload(
            fullPath: _fullPath,
            length: _source.getTotalSize(),
            metadata: _metadata,
          )
          .then(_receiveUploadId)
          .catchError(_controller.addError);
    } else if (snapshot.bytesTransferred != snapshot.totalBytes) {
      _uploadNextChunk();
    } else {
      _currentSnapshot = TaskSnapshot._(
        ref: _ref,
        bytesTransferred: snapshot.bytesTransferred,
        totalBytes: snapshot.totalBytes,
        state: TaskState.success,
      );
    }
  }

  void _receiveUploadId(String uploadId) {
    _uploadId = uploadId;
    _uploadNextChunk();
  }

  Future<void> _uploadNextChunk() async {
    final chunkSize = (_chunkSize * 2).clamp(
      _chunkedUploadBaseChunkSize,
      _uploadChunkMaxSize,
    );

    try {
      final data = await _source.read(_offset, chunkSize);
      final isFinalChunk = _offset + data.length == _source.getTotalSize();

      void onSuccess(_) {
        _offset += data.length;
        _chunkSize = chunkSize;

        _snapshot = TaskSnapshot._(
          ref: _ref,
          bytesTransferred: _offset + data.length,
          totalBytes: _source.getTotalSize(),
          state: isFinalChunk ? TaskState.success : TaskState.running,
        );
      }

      void onError(err) {
        _controller.addError(err);
      }

      _ref.storage._apiClient
          .uploadChunk(
            name: _fullPath,
            uploadId: _uploadId,
            offset: _offset,
            data: data,
            finalize: isFinalChunk,
          )
          .then(onSuccess)
          .catchError(onError);
    } catch (e) {
      _controller.addError(e);
    }
  }
}
