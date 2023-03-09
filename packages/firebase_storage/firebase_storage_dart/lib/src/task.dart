// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A class representing an on-going storage task that additionally delegates to a [Future].
abstract class Task implements Future<TaskSnapshot> {
  final Reference _ref;
  final String _fullPath;
  final Completer<TaskSnapshot> _completer = Completer<TaskSnapshot>();

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

  final _cancelSignal = Signal();
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

  Completer<TaskSnapshot> get _completer;
  Reference get _ref;
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

    return Future.value(true);
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
        _controller.addError(FirebaseStorageException._fromCode(errorCode));
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
      await storage._api.uploadMultipart(
        _fullPath,
        data,
        metadata: metadata,
        cancelSignal: _cancelSignal,
      );

      snapshot = TaskSnapshot._(
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
      _uploadChunk();
      return;
    }

    if (snapshot.bytesTransferred == snapshot.totalBytes) {
      _finalize();
      return;
    }
  }

  void _startUpload() {
    _ref.storage._api
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
    _uploadChunk();
  }

  Future<void> _uploadChunk() async {
    final chunkSize = _chunkSize.clamp(
      _chunkedUploadBaseChunkSize,
      _uploadChunkMaxSize,
    );

    try {
      final data = await _source.read(_offset, chunkSize);
      final isFinalChunk = data.length < chunkSize ||
          _offset + data.length == _source.getTotalSize();

      void onSuccess(_) {
        _cancelSignal.dispose();

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
        _cancelSignal.dispose();

        if (err is CancelledByClientException) return;
        if (snapshot.state != TaskState.running) return;

        if (err is TimeoutException) {
          _chunkSize = chunkSize ~/ 2;
          _uploadChunk();
        } else {
          _controller.addError(err);
        }
      }

      _ref.storage._api
          .uploadChunk(
            name: _fullPath,
            uploadId: _uploadId,
            offset: _offset,
            data: data,
            finalize: isFinalChunk,
            cancelSignal: _cancelSignal,
            onTimeout: () {
              throw TimeoutException('Upload timed out');
            },
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

class _DownloadTask extends DownloadTask with _ProgressEvents {
  final File _file;
  late final IOSink _sink;
  int _offset = 0;
  int _donwloadSize = -1;
  String? _downloadUrl;

  _DownloadTask(
    super.ref,
    super.fullPath,
    File file,
  ) : _file = file {
    _init();

    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
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

  @override
  Future<bool> cancel() async {
    if (await super.cancel()) {
      _file.deleteSync();
      return true;
    }

    return false;
  }

  void _handleError(Object error) {
    if (_file.existsSync()) {
      _file.deleteSync();
      _sink.close();
    }

    if (snapshot.state._isFinal) return;
    _controller.addError(error);
  }

  Future<void> _startDownload() async {
    try {
      if (_donwloadSize == -1) {
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
      final dataStreamFuture = await _ref.storage._api.getStreamedData(
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

      final sub = dataStreamFuture.listen(
        _receiveChunk,
        onError: _handleError,
        cancelOnError: true,
      );

      _cancelSignal.onReceive(sub.cancel);
    } catch (error) {
      _handleError(error);
    }
  }

  void _receiveChunk(List<int> data) async {
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

  @override
  void _handleRunning(TaskSnapshot snapshot) {
    if (snapshot.bytesTransferred == snapshot.totalBytes) {
      _finalize();
    }
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
