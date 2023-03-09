part of firebase_storage_desktop;

class TaskSnapshotDesktop extends TaskSnapshotPlatform {
  final FirebaseStoragePlatform storage;
  final storage_dart.TaskSnapshot _delegate;

  static TaskState platformStateFromDart(storage_dart.TaskState state) {
    switch (state) {
      case storage_dart.TaskState.paused:
        return TaskState.paused;
      case storage_dart.TaskState.running:
        return TaskState.running;
      case storage_dart.TaskState.success:
        return TaskState.success;
      case storage_dart.TaskState.canceled:
        return TaskState.canceled;
      case storage_dart.TaskState.error:
        return TaskState.error;
    }
  }

  TaskSnapshotDesktop(
    this._delegate,
    this.storage,
    super._state, [
    // data is not needed, since all getters are overridden
    super._data = const {},
  ]);

  @override
  int get bytesTransferred => _delegate.bytesTransferred;

  @override
  FullMetadata? get metadata => _delegate.metadata == null
      ? null
      : FullMetadata(_delegate.metadata!.asMap());

  @override
  ReferencePlatform get ref {
    return ReferenceDesktop(_delegate.storage, storage, _delegate.ref.fullPath);
  }

  @override
  TaskState get state => platformStateFromDart(_delegate.state);

  @override
  int get totalBytes => _delegate.totalBytes;
}
