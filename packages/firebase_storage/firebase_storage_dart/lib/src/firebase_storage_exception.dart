// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/src/api/errors.dart';

/// Wrap the errors from the Identity Platform REST API, usually of type `DetailedApiRequestError`
/// in a in a Firebase-friendly format to users.
class FirebaseStorageException extends FirebaseException implements Exception {
  // ignore: public_member_api_docs
  FirebaseStorageException(StorageErrorCode errorCode, {String? message})
      : super(
          plugin: 'firebase_auth',
          code: errorCode.asString,
          message: message ?? errorCode.message,
        );
}
