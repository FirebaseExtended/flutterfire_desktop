part of firebase_storage_dart;

class ListOptions {
  const ListOptions({
    this.maxResults,
    this.pageToken,
  });

  final int? maxResults;
  final String? pageToken;
}
