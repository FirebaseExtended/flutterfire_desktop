part of firebase_storage_dart;

class ListResult {
  final FirebaseStorage storage;
  final List<Reference> items;
  final List<Reference> prefixes;
  final String? nextPageToken;

  ListResult._({
    required this.storage,
    required this.items,
    required this.prefixes,
    this.nextPageToken,
  });

  factory ListResult._fromJson(
    FirebaseStorage storage,
    Map<String, dynamic> json,
  ) {
    return ListResult._(
      storage: storage,
      items: (json['items'] as List)
          .map((e) => storage.ref(e['name'] as String))
          .toList(),
      prefixes: (json['prefixes'] as List)
          .map((e) => storage.ref(e as String))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  ListResult _concat(ListResult other) {
    return ListResult._(
      storage: storage,
      items: [...items, ...other.items],
      prefixes: [...prefixes, ...other.prefixes],
      nextPageToken: other.nextPageToken,
    );
  }
}
