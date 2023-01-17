part of firebase_storage_dart;

class HttpClient {
  final Uri baseUri;
  static final Map<String, HttpClient> _requests = {};
  late final http.Client _client;

  HttpClient._(this.baseUri) {
    _client = http.Client();
  }

  factory HttpClient(Uri baseUri) {
    return _requests[baseUri.toString()] ??= HttpClient._(baseUri);
  }

  Uri getRequestUri({
    Map<String, dynamic>? queryParameters,
    List<String>? pathSegments,
  }) {
    return Uri(
      host: baseUri.host,
      scheme: baseUri.scheme,
      port: baseUri.port,
      pathSegments: [...baseUri.pathSegments, ...pathSegments ?? []],
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> _request({
    required String method,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    final uri = getRequestUri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );

    final req = http.Request(method, uri);

    if (bodyBytes != null) {
      req.bodyBytes = bodyBytes;
    }

    return _client.send(req).then((res) => http.Response.fromStream(res));
  }

  Future<http.Response> get({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> post({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'POST',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> postMultipart({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = getRequestUri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );

    final req = http.MultipartRequest('POST', uri);

    if (fields != null) {
      req.fields.addAll(fields);
    }

    if (files != null) {
      req.files.addAll(files);
    }

    final streamedResponse = await _client.send(req);
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> put({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'PUT',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> delete({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'DELETE',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> patch({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'PATCH',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> head({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'HEAD',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> options({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'OPTIONS',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> update({
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'UPDATE',
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  void dispose() {
    final key = baseUri.toString();
    _requests[key]?._client.close();
  }
}
