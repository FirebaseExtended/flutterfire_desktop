// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A class representing an on-going storage task that additionally delegates to a [Future].
abstract class Task implements Future<TaskSnapshot> {
  final Reference _ref;
  final String _fullPath;
  late Completer<TaskSnapshot> _completer;

  /// The latest [TaskSnapshot] for this task.
  late TaskSnapshot snapshot;

  /// The [FirebaseStorage] instance associated with this task.
  FirebaseStorage get storage => _ref.storage;

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// await this [Task] directly.
  Stream<TaskSnapshot> get snapshotEvents;

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.

  Task(this._ref, this._fullPath);

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
  Stream<TaskSnapshot> asStream() {
    return _completer.future.asStream();
  }

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _completer.future.catchError(onError, test: test);
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot p1) onValue, {
    Function? onError,
  }) async {
    return await _completer.future.then(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) {
    return _completer.future.whenComplete(action);
  }

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) {
    return _completer.future.timeout(timeLimit, onTimeout: onTimeout);
  }
}

const _uploadChunkMaxSize = 32 * 1024 * 1024;
const _chunkedUploadBaseChunkSize = 256 * 1024;

/// A class which indicates an on-going upload task.
abstract class UploadTask extends Task implements Future<TaskSnapshot> {
  UploadTask(super.ref, super.fullPath);
}

/// A class which indicates an on-going download task.
abstract class DownloadTask extends Task implements Future<TaskSnapshot> {
  DownloadTask(super.ref, super.fullPath);
}

abstract class _ProgressEvents {
  final _controller = StreamController<TaskSnapshot>.broadcast();
  late final StreamSubscription<TaskSnapshot> _subscription;

  Reference get _ref;
  final Completer<TaskSnapshot> _completer = Completer<TaskSnapshot>();
  Signal get _cancelSignal;

  late TaskSnapshot _snapshot;
  TaskSnapshot get snapshot => _snapshot;

  Stream<TaskSnapshot> get snapshotEvents => _controller.stream;

  set _currentSnapshot(TaskSnapshot value) {
    _snapshot = value;
    _controller.add(value);
  }

  Future<bool> cancel() async {
    if (snapshot.state._isFinal) {
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

  Future<bool> pause() {
    if (snapshot.state != TaskState.running) {
      return Future.value(false);
    }

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.bytesTransferred,
      totalBytes: snapshot.totalBytes,
      state: TaskState.paused,
    );

    return Future.value(false);
  }

  Future<bool> resume() {
    if (snapshot.state != TaskState.paused) {
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

  Stream<TaskSnapshot> asStream() {
    return Stream.fromFuture(_completer.future);
  }

  void _init() {
    _subscription = _controller.stream.listen(
      _onSnapshot,
      onDone: _onDone,
      onError: _onError,
    );
  }

  void _onDone() {
    _completer.complete(snapshot);
    _subscription.cancel();
  }

  void _onError(error) {
    _completer.completeError(error);
    _subscription.cancel();
  }

  void _handleRunning(TaskSnapshot snapshot) {}

  void _onSnapshot(TaskSnapshot snapshot) {
    switch (snapshot.state) {
      case TaskState.error:
      case TaskState.success:
        _controller.close();
        break;

      case TaskState.canceled:
        _cancelSignal.send();

        final errorCode = StorageErrorCode.canceled;
        _controller.addError(errorCode);
        break;

      case TaskState.paused:
        _cancelSignal.send();
        break;

      case TaskState.running:
        _handleRunning(snapshot);
        break;
    }
  }
}

class _MultipartUploadTask extends UploadTask {
  final Uint8List data;
  final SettableMetadata? metadata;
  final Signal _cancelSignal = Signal();

  _MultipartUploadTask._(
    super.ref,
    super.fullPath,
    this.data, [
    this.metadata,
  ]) {
    _upload();
  }

  @override
  Future<bool> cancel() async {
    if (snapshot.state != TaskState.running &&
        snapshot.state != TaskState.paused) {
      return false;
    }

    _cancelSignal.send();
    _completer.completeError(FirebaseStorageException._fromCode(
      StorageErrorCode.canceled,
    ));

    return true;
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

  Future<void> _upload() async {
    try {
      await storage._apiClient.uploadMultipart(
        _fullPath,
        data,
        metadata: metadata,
        cancelSignal: _cancelSignal,
      );

      final snapshot = TaskSnapshot._(
        ref: _ref,
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

class _ChunkedUploadTask extends UploadTask with _ProgressEvents {
  final Source _source;
  final SettableMetadata? _metadata;
  late String _uploadId;

  int _offset = 0;
  int _chunkSize = _chunkedUploadBaseChunkSize;

  @override
  Signal _cancelSignal = Signal();

  @override
  Stream<TaskSnapshot> get snapshotEvents => _controller.stream;

  _ChunkedUploadTask._(
    super.ref,
    super.fullPath,
    this._source, [
    this._metadata,
  ]) {
    _init();

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: 0,
      totalBytes: _source.getTotalSize(),
      state: TaskState.running,
    );
  }

  @override
  void _handleRunning(TaskSnapshot snapshot) {
    if (snapshot.bytesTransferred == 0) {
      return _startUpload();
    }

    if (snapshot.bytesTransferred != snapshot.totalBytes) {
      Future.microtask(() => _uploadNextChunk());
      return;
    }

    if (snapshot.bytesTransferred == snapshot.totalBytes) {
      _finalize();
      return;
    }
  }

  void _startUpload() {
    _ref.storage._apiClient
        .startChunkedUpload(
          fullPath: _fullPath,
          length: _source.getTotalSize(),
          metadata: _metadata,
        )
        .then(_receiveUploadId)
        .catchError(_controller.addError);
  }

  void _receiveUploadId(String uploadId) {
    _uploadId = uploadId;
    _uploadNextChunk();
  }

  Future<void> _uploadNextChunk() async {
    final chunkSize = _chunkSize.clamp(
      _chunkedUploadBaseChunkSize,
      _uploadChunkMaxSize,
    );

    try {
      final data = await _source.read(_offset, chunkSize);
      final isFinalChunk = data.length < chunkSize ||
          _offset + data.length == _source.getTotalSize();

      void onSuccess(_) {
        // ignoring the response if task was canceled or paused.
        if (snapshot.state != TaskState.running) return;
        _offset += data.length;
        _chunkSize = chunkSize * 2;

        _currentSnapshot = TaskSnapshot._(
          ref: _ref,
          bytesTransferred: _offset,
          totalBytes: _source.getTotalSize(),
          state: isFinalChunk ? TaskState.success : TaskState.running,
        );
      }

      void onError(err) {
        if (snapshot.state != TaskState.running) return;
        _controller.addError(err);
      }

      _cancelSignal = Signal();

      _ref.storage._apiClient
          .uploadChunk(
            name: _fullPath,
            uploadId: _uploadId,
            offset: _offset,
            data: data,
            finalize: isFinalChunk,
            cancelSignal: _cancelSignal,
          )
          .then(onSuccess)
          .catchError(onError);
    } catch (e) {
      _controller.addError(e);
    }
  }

  void _finalize() {
    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.bytesTransferred,
      totalBytes: snapshot.totalBytes,
      state: TaskState.success,
    );
  }
}

final _maxFiniteInt = double.maxFinite.toInt();

class _DownloadTask extends DownloadTask with _ProgressEvents {
  @override
  Signal get _cancelSignal => Signal();

  final File _file;
  late final IOSink _sink;
  int _offset = 0;
  int _donwloadSize = _maxFiniteInt;
  String? _downloadUrl;

  _DownloadTask(
    super.ref,
    super.fullPath,
    File file,
  ) : _file = file {
    _init();

    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
      catchError(
        (_) => _file.deleteSync(),
        test: (e) =>
            e is FirebaseStorageException &&
            e.code == StorageErrorCode.canceled.code,
      );
    } else {
      _offset = _file.lengthSync();
    }

    _sink = _file.openWrite();

    _snapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: _offset,
      totalBytes: _donwloadSize,
      state: TaskState.running,
    );

    _startDownload();
  }

  @override
  Future<bool> resume() async {
    final shouldResume = await super.resume();
    if (!shouldResume) return false;

    if (_downloadUrl != null) {
      _openDownloadStream(_downloadUrl!);
    } else {
      _startDownload();
    }

    return shouldResume;
  }

  void _handleError(Object error) {
    if (snapshot.state._isFinal) return;
    _controller.addError(error);
  }

  Future<void> _startDownload() async {
    try {
      if (_donwloadSize == _maxFiniteInt) {
        final meta = await _ref.getMetadata();
        _donwloadSize = meta.size!;
      }

      _downloadUrl ??= await _ref.getDownloadURL();
      _openDownloadStream(_downloadUrl!);
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> _openDownloadStream(String url) async {
    try {
      final dataStreamFuture = await _ref.storage._apiClient.getStreamedData(
        Uri.parse(url),
        offset: _offset,
        cancelSignal: _cancelSignal,
      );

      _currentSnapshot = TaskSnapshot._(
        ref: _ref,
        bytesTransferred: _offset,
        totalBytes: _donwloadSize,
        state: TaskState.running,
      );

      dataStreamFuture.listen(
        _receiveChunk,
        onError: _handleError,
        onDone: _finalize,
        cancelOnError: true,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  void _receiveChunk(List<int> data) {
    if (snapshot.state != TaskState.running) return;

    _sink.add(data);
    _offset += data.length;

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: _offset,
      totalBytes: snapshot.totalBytes,
      state: TaskState.running,
    );
  }

  Future<void> _finalize() async {
    try {
      await _sink.flush();
      await _sink.close();
    } catch (error) {
      _controller.addError(error);
    }

    _currentSnapshot = TaskSnapshot._(
      ref: _ref,
      bytesTransferred: snapshot.totalBytes,
      totalBytes: snapshot.totalBytes,
      state: TaskState.success,
    );
  }
}
