// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_storage_desktop/src/desktop_reference.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

/// Implementation for a [TaskSnapshotPlatform].
class DesktopTaskSnapshot extends TaskSnapshotPlatform {
  // ignore: public_member_api_docs
  DesktopTaskSnapshot(this.storage, TaskState state, this._data)
      : super(state, _data);

  /// The [FirebaseStoragePlatform] used to create the task.
  final FirebaseStoragePlatform storage;

  final Map<String, dynamic> _data;

  @override
  ReferencePlatform get ref {
    return DesktopReference(storage, _data['path']);
  }
}
