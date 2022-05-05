part of firebase_storage_dart;

/// A class representing an on-going storage task that additionally delegates to a [Future].
abstract class Task implements Future<TaskSnapshot> {
  Task._(
    this.storage,
  );

  /// The [FirebaseStorage] instance associated with this task.
  final FirebaseStorage storage;

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// await this [Task] directly.
  Stream<TaskSnapshot> get snapshotEvents {
    throw UnimplementedError();
    // return _delegate.snapshotEvents
    //     .map((snapshotDelegate) => TaskSnapshot._(storage, snapshotDelegate));
  }

  /// The latest [TaskSnapshot] for this task.
  TaskSnapshot get snapshot {
    throw UnimplementedError();
    // return TaskSnapshot._(storage, _delegate.snapshot);
  }

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.
  Future<bool> pause() async {
    if (snapshot.state == TaskState.paused) {
      return true;
    }
    throw UnimplementedError();
    // final paused = _task.pause();
    // // Wait until the snapshot is paused, then return the value of paused...
    // return snapshotEvents
    //     .takeWhile((snapshot) => snapshot.state != TaskState.paused)
    //     .last
    //     .then<bool>((_) => paused);
  }

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.running]
  /// state.
  Future<bool> resume() {
    throw UnimplementedError();
    // _delegate.resume();
  }

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the delegating task Future
  /// and stream ([snapshotEvents]) will trigger an error with a [FirebaseException].
  Future<bool> cancel() {
    throw UnimplementedError();
    //  _delegate.cancel();
  }

  @override
  Stream<TaskSnapshot> asStream() {
    throw UnimplementedError();
    // _delegate.onComplete.asStream().map((_) => snapshot);
  }

  @override
  Future<TaskSnapshot> catchError(Function onError,
      {bool Function(Object error)? test}) async {
    throw UnimplementedError();
    // await _delegate.onComplete.catchError(onError, test: test);
    // return snapshot;
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(TaskSnapshot) onValue,
      {Function? onError}) {
    throw UnimplementedError();
    // _delegate.onComplete.then((_) {
    //   return onValue(snapshot);
    // }, onError: onError);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) async {
    throw UnimplementedError();
    // await _delegate.onComplete.whenComplete(action);
    // return snapshot;
  }

  @override
  Future<TaskSnapshot> timeout(Duration timeLimit,
      {FutureOr<TaskSnapshot> Function()? onTimeout}) {
    throw UnimplementedError();
    // _delegate.onComplete
    //   .then((_) => snapshot)
    //   .timeout(timeLimit, onTimeout: onTimeout);
  }
}

/// A class which indicates an on-going upload task.
class UploadTask extends Task {
  UploadTask._(
    FirebaseStorage storage,
  ) : super._(
          storage,
        );
}

/// A class which indicates an on-going download task.
class DownloadTask extends Task {
  DownloadTask._(FirebaseStorage storage)
      : super._(
          storage,
        );
}
