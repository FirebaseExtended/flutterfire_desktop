// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A [TaskSnapshot] is returned as the result or on-going process of a [Task].
class TaskSnapshot {
  TaskSnapshot._(this.storage, this.ref);

  /// The [FirebaseStorage] instance used to create the task.
  final FirebaseStorage storage;

  /// The current transferred bytes of this task.
  // TODO:
  int get bytesTransferred => throw UnimplementedError();

  /// The [FullMetadata] associated with this task.
  ///
  /// May be `null` if no metadata exists.
  // TODO:
  FullMetadata? get metadata => throw UnimplementedError();

  /// The [Reference] for this snapshot.
  final Reference ref;

  /// The current task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  // TODO:
  TaskState get state => throw UnimplementedError();

  /// The total bytes of the task.
  ///
  /// Note; when performing a download task, the value of `-1` will be provided
  /// whilst the total size of the remote file is being determined.
  // TODO:
  int get totalBytes => throw UnimplementedError();

  @override
  bool operator ==(Object other) =>
      other is TaskSnapshot && other.ref == ref && other.storage == storage;

  @override
  int get hashCode => Object.hash(storage, ref);

  @override
  String toString() => '$TaskSnapshot(ref: $ref, state: $state)';
}
