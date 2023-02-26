part of firebase_storage_dart;

enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  final String value;
  const HttpMethod(this.value);
}

class Response {
  final int statusCode;
  final HttpHeaders headers;
  final Uint8List bodyBytes;
  final Stream<List<int>>? stream;

  String get body => utf8.decode(bodyBytes);

  Response({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
    this.stream,
  });
}

class Signal {
  final List<Function()> _handlers = [];

  void onReceive(Function() handler) {
    _handlers.add(handler);
  }

  void send() {
    for (final handler in _handlers) {
      handler();
    }

    dispose();
  }

  void dispose() {
    _handlers.clear();
  }
}

class CancelledByClientException implements Exception {}

class RetryClient {
  final Uri baseUri;
  static final Map<String, RetryClient> _requests = {};
  static String? _authToken;

  late final HttpClient _ioClient;

  RetryClient._(this.baseUri) {
    _ioClient = HttpClient();
  }

  factory RetryClient(Uri baseUri) {
    return _requests[baseUri.toString()] ??= RetryClient._(baseUri);
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

  Future<Response> request({
    required HttpMethod method,
    Uri? uri,
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
    Signal? cancelSignal,
    bool awaitBody = true,
  }) async {
    uri ??= getRequestUri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );

    final req = await _ioClient.openUrl(method.value, uri);

    cancelSignal?.onReceive(() {
      req.abort(CancelledByClientException());
    });

    if (_authToken != null) {
      headers ??= {};
      headers.addAll({'Authorization': 'Firebase $_authToken'});
    }

    if (headers != null) {
      for (var entry in headers.entries) {
        req.headers.add(entry.key, entry.value);
      }
    }

    return await asyncGuard(() async {
      if (bodyBytes != null) {
        req.add(bodyBytes);
        await req.flush();
      }

      final res = await req.close();

      if (res.statusCode ~/ 100 == 4) {
        throw FirebaseStorageException._fromHttpStatusCode(
          res.statusCode,
          StackTrace.current,
        );
      }

      if (!awaitBody) {
        return Response(
          statusCode: res.statusCode,
          headers: res.headers,
          bodyBytes: Uint8List(0),
          stream: res,
        );
      }

      final resBytes = await res.expand((e) => e).toList();

      return Response(
        statusCode: res.statusCode,
        headers: res.headers,
        bodyBytes: Uint8List.fromList(resBytes),
      );
    });
  }

  void dispose() {
    final key = baseUri.toString();
    _requests[key]?._ioClient.close();
    _requests[key] = RetryClient._(baseUri);
  }
}
