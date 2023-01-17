// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A class representing an on-going storage task that additionally delegates to a [Future].
abstract class Task implements Future<TaskSnapshot> {
  Task._(this.storage);

  /// The [FirebaseStorage] instance associated with this task.
  final FirebaseStorage storage;

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// await this [Task] directly.
  // TODO:
  Stream<TaskSnapshot> get snapshotEvents => throw UnimplementedError();

  /// The latest [TaskSnapshot] for this task.
  // TODO:
  TaskSnapshot get snapshot => throw UnimplementedError();

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.
  // TODO:
  Future<bool> pause() => throw UnimplementedError();

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.running]
  /// state.
  // TODO:
  Future<bool> resume() => throw UnimplementedError();

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the delegating task Future
  /// and stream ([snapshotEvents]) will trigger an error with a [FirebaseException].
  // TODO:
  Future<bool> cancel() => throw UnimplementedError();

  // TODO:
  @override
  Stream<TaskSnapshot> asStream() => throw UnimplementedError();

  // TODO:
  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) async {
    throw UnimplementedError();
  }

  // TODO:
  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) {
    throw UnimplementedError();
  }

  // TODO:
  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) async {
    throw UnimplementedError();
  }

  // TODO:
  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) {
    throw UnimplementedError();
  }
}

const _multipartUploadMaxSize = 256 * 1024 * 1024;
const _resumableUploadBaseChunkSize = 256 * 1024;

/// A class which indicates an on-going upload task.
class UploadTask extends Task {
  UploadTask._(FirebaseStorage storage) : super._(storage);
}

/// A class which indicates an on-going download task.
class DownloadTask extends Task {
  DownloadTask._(FirebaseStorage storage) : super._(storage);
}

class MultipartUploadTask implements UploadTask {
  final StreamController<TaskSnapshot> controller = StreamController();
  @override
  final FirebaseStorage storage;
  final Uint8List data;
  final SettableMetadata? metadata;
  final String fullPath;

  @override
  late TaskSnapshot snapshot;

  late StreamSubscription<TaskSnapshot> _subscription;

  MultipartUploadTask._(
    this.storage,
    this.fullPath,
    this.data, [
    this.metadata,
  ]) {
    _subscription = controller.stream.listen(_onSnapshot);
  }

  void _onSnapshot(TaskSnapshot snapshot) {
    this.snapshot = snapshot;
  }

  @override
  Stream<TaskSnapshot> asStream() {
    return controller.stream;
  }

  @override
  Future<bool> cancel() async {
    if (snapshot.state == TaskState.running) {
      _subscription.cancel();
      return true;
    }

    return false;
  }

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return controller.stream.last.catchError(onError, test: test);
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
    return controller.stream.last.then(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) {
    return controller.stream.last.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) {
    return controller.stream.last.whenComplete(action);
  }
}
