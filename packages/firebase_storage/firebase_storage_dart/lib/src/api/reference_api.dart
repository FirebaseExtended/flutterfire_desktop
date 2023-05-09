part of api;

/// Request to verify a custom token
class ReferenceListRessultRequestArgument {
  Location location;
  String? delimiter;
  String? pageToken;
  int? maxResults;
  ReferenceListRessultRequestArgument({
    required this.location,
    this.delimiter,
    this.pageToken,
    this.maxResults,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> urlParams = {};
    if (location.isRoot) {
      urlParams['prefix'] = '';
    } else {
      urlParams['prefix'] = location.path + '/';
    }
    final s = delimiter?.isNotEmpty;
    if (delimiter != null && s == true) {
      urlParams['delimiter'] = delimiter;
    }
    if (pageToken != null) {
      urlParams['pageToken'] = pageToken;
    }
    if (maxResults != null) {
      urlParams['maxResults'] = maxResults;
    }
    return urlParams;
  }
}
