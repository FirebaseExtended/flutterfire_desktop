// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage_dart;

/// A [TaskSnapshot] is returned as the result or on-going process of a [Task].
class TaskSnapshot {
  /// The [FirebaseStorage] instance used to create the task.
  FirebaseStorage get storage => ref.storage;

  /// The current transferred bytes of this task.
  final int bytesTransferred;

  /// The [FullMetadata] associated with this task.
  ///
  /// May be `null` if no metadata exists.
  final FullMetadata? metadata;

  /// The [Reference] for this snapshot.
  final Reference ref;

  /// The current task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  final TaskState state;

  /// The total bytes of the task.
  ///
  /// Note; when performing a download task, the value of `-1` will be provided
  /// whilst the total size of the remote file is being determined.
  final int totalBytes;

  TaskSnapshot._({
    required this.ref,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.state,
    // ignore: unused_element
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      other is TaskSnapshot && other.ref == ref && other.storage == storage;

  @override
  int get hashCode => Object.hash(storage, ref);

  @override
  String toString() => '$TaskSnapshot(ref: $ref, state: $state)';
}
