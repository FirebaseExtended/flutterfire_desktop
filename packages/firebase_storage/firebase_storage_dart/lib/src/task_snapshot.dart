part of firebase_storage_dart;

/// A [TaskSnapshot] is returned as the result or on-going process of a [Task].
class TaskSnapshot {
  TaskSnapshot._(this.storage, this._data);

  /// The [FirebaseStorage] instance used to create the task.
  final FirebaseStorage storage;
  final Map<String, dynamic> _data;

  /// The current transferred bytes of this task.
  int get bytesTransferred => _data['bytesTransferred'];

  /// The [FullMetadata] associated with this task.
  ///
  /// May be `null` if no metadata exists.
  FullMetadata? get metadata => _data['metadata'];

  /// The [Reference] for this snapshot.
  Reference get ref {
    return Reference._(storage, _data['path']);
  }

  /// The current task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  TaskState get state => _data['state'];

  /// The total bytes of the task.
  ///
  /// Note; when performing a download task, the value of `-1` will be provided
  /// whilst the total size of the remote file is being determined.
  int get totalBytes => _data['totalBytes'];

  @override
  bool operator ==(Object other) =>
      other is TaskSnapshot && other.ref == ref && other.storage == storage;

  @override
  int get hashCode => Object.hashAll([storage, ref]);

  @override
  String toString() => '$TaskSnapshot(ref: $ref, state: $state)';
}
