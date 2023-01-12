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

  factory ListResult._fromObjects({
    required gapi.Objects objects,
    required Reference src,
  }) {
    final items = <Reference>[];

    for (var item in objects.items ?? <gapi.Object>[]) {
      final name = path.basename(item.name!);
      if (name.isEmpty || name == src.name) continue;

      items.add(src.child(name));
    }

    final prefixes = (objects.prefixes ?? <String>[])
        .map((e) => src.storage.ref(e))
        .toList();

    return ListResult._(
      storage: src.storage,
      items: items,
      prefixes: prefixes,
      nextPageToken: objects.nextPageToken,
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
