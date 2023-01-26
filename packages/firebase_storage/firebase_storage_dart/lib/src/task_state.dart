// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_storage_dart;

/// Represents the state of an on-going [Task].
///
/// The state can be accessed directly via a [TaskSnapshot].
enum TaskState {
  /// Indicates the task has been paused by the user.
  paused(false),

  /// Indicates the task is currently in-progress.
  running(false),

  /// Indicates the task has successfully completed.
  success(true),

  /// Indicates the task was canceled.
  canceled(true),

  /// Indicates the task failed with an error.
  error(true);

  const TaskState(this._isFinal);

  final bool _isFinal;
}
