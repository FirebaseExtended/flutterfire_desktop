// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_storage_desktop/src/desktop_reference.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

/// Implementation for a [ListResultPlatform].
class DesktopListResult extends ListResultPlatform {
  // ignore: public_member_api_docs
  DesktopListResult(
    FirebaseStoragePlatform storage, {
    String? nextPageToken,
    List<String>? items,
    List<String>? prefixes,
  })  : _items = items ?? [],
        _prefixes = prefixes ?? [],
        super(storage, nextPageToken);

  List<String> _items;

  List<String> _prefixes;

  @override
  List<ReferencePlatform> get items {
    return _items.map((path) => DesktopReference(storage!, path)).toList();
  }

  @override
  List<ReferencePlatform> get prefixes {
    return _prefixes.map((path) => DesktopReference(storage!, path)).toList();
  }
}
