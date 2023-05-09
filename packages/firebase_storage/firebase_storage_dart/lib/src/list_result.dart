part of firebase_storage_dart;

/// Class returned as a result of calling a list method ([list] or [listAll])
/// on a [Reference].
class ListResult {
  ListResult(this.storage, String? nextPageToken, List<String> items,
      List<String> prefixes)
      : _nextPageToken = nextPageToken,
        _items = items,
        _prefixes = prefixes;

  /// The [FirebaseStorage] instance for this result.
  final FirebaseStorage storage;
  final String? _nextPageToken;
  final List<String> _items;

  final List<String> _prefixes;

  /// Objects in this directory.
  ///
  /// Returns a [List] of [Reference] instances.
  List<Reference> get items {
    return _items
        .map((path) => Reference._(storage, Location(path, storage.bucket)))
        .toList();
  }

  /// If set, there might be more results for this list.
  ///
  /// Use this token to resume the list with [ListOptions].
  String? get nextPageToken => _nextPageToken;

  /// References to prefixes (sub-folders). You can call list() on them to get
  /// its contents.
  ///
  /// Folders are implicit based on '/' in the object paths. For example, if a
  /// bucket has two objects '/a/b/1' and '/a/b/2', list('/a') will return '/a/b'
  /// as a prefix.

  List<Reference> get prefixes {
    return _prefixes
        .map((path) => Reference._(storage, Location(path, storage.bucket)))
        .toList();
  }
}
