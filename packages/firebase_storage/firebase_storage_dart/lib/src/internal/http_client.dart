part of firebase_storage_dart;

class HttpClient {
  final Uri baseUri;
  static final Map<String, HttpClient> _requests = {};
  static String? _authToken;

  late final http.Client _rawHttpClient;

  HttpClient._(this.baseUri) {
    _rawHttpClient = http.Client();
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
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) async {
    final uri = getRequestUri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );

    final req = http.Request(method, uri);

    if (_authToken != null) {
      headers ??= {};
      headers.addAll({'Authorization': 'Firebase $_authToken'});
    }

    if (headers != null) {
      req.headers.addAll(headers);
    }

    if (bodyBytes != null) {
      req.bodyBytes = bodyBytes;
    }

    return await asyncGuard(() async {
      final streamedRes = await _rawHttpClient.send(req);
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode ~/ 100 == 4) {
        throw FirebaseStorageException._fromHttpStatusCode(
          res.statusCode,
          StackTrace.current,
        );
      }

      return res;
    });
  }

  Future<http.Response> get({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> post({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'POST',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> put({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'PUT',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> delete({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'DELETE',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> patch({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'PATCH',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  Future<http.Response> head({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'HEAD',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> update({
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
  }) {
    return _request(
      method: 'UPDATE',
      headers: headers,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
      bodyBytes: bodyBytes,
    );
  }

  void dispose() {
    final key = baseUri.toString();
    _requests[key]?._rawHttpClient.close();
    _requests[key] = HttpClient._(baseUri);
  }
}
