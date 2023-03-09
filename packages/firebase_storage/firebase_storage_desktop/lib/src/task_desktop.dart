part of firebase_storage_desktop;

class TaskDesktop extends TaskPlatform implements Future<TaskSnapshotDesktop> {
  final FirebaseStoragePlatform storage;
  final storage_dart.Task _delegate;

  TaskDesktop(this._delegate, this.storage);

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return _delegate.snapshotEvents.map(
      (event) {
        return TaskSnapshotDesktop(event, storage, TaskState.running);
      },
    ).handleError(platformErrorGuard);
  }

  @override
  TaskSnapshotPlatform get snapshot {
    return TaskSnapshotDesktop(
      _delegate.snapshot,
      storage,
      TaskSnapshotDesktop.platformStateFromDart(_delegate.snapshot.state),
    );
  }

  @override
  Future<TaskSnapshotPlatform> get onComplete async {
    final snapshot = await platformErrorFutureGuard(_delegate);

    return TaskSnapshotDesktop(
      snapshot,
      storage,
      TaskSnapshotDesktop.platformStateFromDart(snapshot.state),
    );
  }

  @override
  Future<bool> pause() => platformErrorAsyncGuard(_delegate.pause);

  @override
  Future<bool> resume() => platformErrorAsyncGuard(_delegate.resume);

  @override
  Future<bool> cancel() => platformErrorAsyncGuard(_delegate.cancel);

  @override
  Stream<TaskSnapshotDesktop> asStream() {
    return _delegate.asStream().map(
      (event) {
        return TaskSnapshotDesktop(
          event,
          storage,
          TaskSnapshotDesktop.platformStateFromDart(event.state),
        );
      },
    );
  }

  @override
  Future<TaskSnapshotDesktop> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _delegate.catchError(platformErrorGuard, test: test).then((value) {
      return TaskSnapshotDesktop(
        value,
        storage,
        TaskSnapshotDesktop.platformStateFromDart(value.state),
      );
    });
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshotDesktop value) onValue, {
    Function? onError,
  }) {
    return _delegate.then((value) {
      return onValue(TaskSnapshotDesktop(
        value,
        storage,
        TaskSnapshotDesktop.platformStateFromDart(value.state),
      ));
    }, onError: platformErrorGuard);
  }

  @override
  Future<TaskSnapshotDesktop> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshotDesktop> Function()? onTimeout,
  }) {
    return _delegate
        .timeout(timeLimit,
            onTimeout: onTimeout == null
                ? null
                : () {
                    final v = onTimeout.call();
                    if (v is Future) {
                      return (v as Future<TaskSnapshotDesktop>).then((value) {
                        return value._delegate;
                      });
                    } else {
                      return v._delegate;
                    }
                  })
        .then((value) {
      return TaskSnapshotDesktop(
        value,
        storage,
        TaskSnapshotDesktop.platformStateFromDart(value.state),
      );
    });
  }

  @override
  Future<TaskSnapshotDesktop> whenComplete(
    FutureOr<void> Function() action,
  ) async {
    final s = await platformErrorAsyncGuard(
      () => _delegate.whenComplete(action),
    );

    return TaskSnapshotDesktop(
      s,
      storage,
      TaskSnapshotDesktop.platformStateFromDart(s.state),
    );
  }
}
