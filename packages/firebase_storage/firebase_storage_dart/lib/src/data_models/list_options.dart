/// The options [FirebaseStoragePlatform.list] accepts.
class ListOptions {
  /// Creates a new [ListOptions] instance.
  const ListOptions({
    this.maxResults,
    this.pageToken,
  });

  /// If set, limits the total number of `prefixes` and `items` to return.
  ///
  /// The default and maximum maxResults is 1000.
  final int? maxResults;

  /// The nextPageToken from a previous call to list().
  ///
  /// If provided, listing is resumed from the previous position.
  final String? pageToken;
}
