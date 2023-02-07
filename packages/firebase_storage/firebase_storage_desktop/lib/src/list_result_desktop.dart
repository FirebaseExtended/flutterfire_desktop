import 'package:firebase_storage_dart/firebase_storage_dart.dart'
    as storage_dart;
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import 'reference_desktop.dart';

class ListResultDesktop extends ListResultPlatform {
  final storage_dart.ListResult _delegate;

  ListResultDesktop(this._delegate, super.storage, super.nextPageToken);

  @override
  List<ReferencePlatform> get items {
    return _delegate.items.map((item) {
      return ReferenceDesktop(_delegate.storage, storage!, item.fullPath);
    }).toList();
  }

  @override
  List<ReferencePlatform> get prefixes {
    return _delegate.prefixes.map((ref) {
      return ReferenceDesktop(_delegate.storage, storage!, ref.fullPath);
    }).toList();
  }
}
