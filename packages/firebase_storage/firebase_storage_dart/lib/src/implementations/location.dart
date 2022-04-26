class Location {
  Location(String path, this.bucket) {
    _path = path;
  }
  final String bucket;
  late String _path;
  String get path => _path;

  bool get isRoot => path.isEmpty;

  String fullServerUrl() {
    return '/b/' +
        Uri.encodeComponent(bucket) +
        '/o/' +
        Uri.encodeComponent(path);
  }

  String bucketOnlyServerUrl() {
    return '/b/' + Uri.encodeComponent(bucket) + '/o';
  }
}
