part of firebase_storage_dart;

class ListResult {
  final FirebaseStorage storage;
  late final List<Reference> items;
  late final List<Reference> prefixes;
  final String? nextPageToken;

  ListResult._({
    required this.storage,
    required Reference src,
    List<String>? prefixes,
    List<gapi.Object>? items,
    this.nextPageToken,
  }) {
    this.items = items?.map((e) => src.child(e.name!)).toList() ?? [];
    this.prefixes = prefixes?.map((e) => src.child(e)).toList() ?? [];
  }
}
