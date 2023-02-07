import 'package:firebase_storage_dart/firebase_storage_dart.dart'
    as storage_dart;

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import 'task_snapshot_desktop.dart';

class TaskDesktop extends TaskPlatform {
  final FirebaseStoragePlatform storage;
  final storage_dart.Task _delegate;

  TaskDesktop(this._delegate, this.storage);

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return _delegate.snapshotEvents.map(
      (event) {
        return TaskSnapshotDesktop(event, storage, TaskState.running);
      },
    );
  }

  @override
  TaskSnapshotPlatform get snapshot {
    return TaskSnapshotDesktop(
      _delegate.snapshot,
      storage,
      TaskSnapshotDesktop.fromDartState(_delegate.snapshot.state),
    );
  }

  @override
  Future<TaskSnapshotPlatform> get onComplete async {
    final snapshot = await _delegate;
    return TaskSnapshotDesktop(
      snapshot,
      storage,
      TaskSnapshotDesktop.fromDartState(snapshot.state),
    );
  }

  @override
  Future<bool> pause() => _delegate.pause();

  @override
  Future<bool> resume() => _delegate.resume();

  @override
  Future<bool> cancel() => _delegate.cancel();
}
