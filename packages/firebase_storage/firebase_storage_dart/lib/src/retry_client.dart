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

class RetryPolicy {
  int maxOperationRetryTime = Duration(minutes: 2).inMilliseconds;
  int maxUploadRetryTime = Duration(minutes: 10).inMilliseconds;
  int maxDownloadRetryTime = Duration(minutes: 10).inMilliseconds;

  Duration waitTimeForRequestType(RequestType requestType) {
    switch (requestType) {
      case RequestType.operation:
        return Duration(milliseconds: maxOperationRetryTime);
      case RequestType.upload:
        return Duration(milliseconds: maxUploadRetryTime);
      case RequestType.download:
        return Duration(milliseconds: maxDownloadRetryTime);
    }
  }

  // https://cloud.google.com/storage/docs/retry-strategy
  static bool isRetryableHttpCode(int statusCode) {
    switch (statusCode) {
      case 408:
        return true;
      case 429:
        return true;
    }

    if (statusCode ~/ 100 == 5) {
      return true;
    }

    return false;
  }
}

enum RequestType {
  upload,
  download,
  operation,
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
  String? authToken;

  late final HttpClient _ioClient;
  final RetryPolicy retryPolicy = RetryPolicy();

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
    RequestType requestType = RequestType.operation,
    Uri? uri,
    Map<String, String>? headers,
    List<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
    List<int>? bodyBytes,
    Signal? cancelSignal,
    bool awaitBody = true,
    void Function()? onTimeout,
  }) async {
    uri ??= getRequestUri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );

    final maxWaitTime = retryPolicy.waitTimeForRequestType(requestType);

    return await asyncGuard(
      () async {
        final req = await _ioClient.openUrl(method.value, uri!);

        cancelSignal?.onReceive(() {
          req.abort(CancelledByClientException());
        });

        if (authToken != null) {
          headers ??= {};
          headers!.addAll({'Authorization': 'Firebase $authToken'});
        }

        if (headers != null) {
          for (var entry in headers!.entries) {
            req.headers.add(entry.key, entry.value);
          }
        }

        if (bodyBytes != null) {
          req.add(bodyBytes);
          await req.flush();
        }

        final res = await req.close();

        if (RetryPolicy.isRetryableHttpCode(res.statusCode)) {
          throw RetryableException(RetryableResponseErrorCode(res.statusCode));
        }

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
      },
      maxWaitTime: maxWaitTime,
      onTimeout: onTimeout,
    );
  }

  void dispose() {
    final key = baseUri.toString();
    _requests[key]?._ioClient.close();
    _requests[key] = RetryClient._(baseUri);
  }
}

// https://cloud.google.com/storage/docs/retry-strategy
Future<T> asyncGuard<T>(
  Future<T> Function() callback, {
  required Duration maxWaitTime,
  void Function()? onTimeout,
}) async {
  var waitTime = Duration(milliseconds: 500);

  while (true) {
    waitTime *= 2;
    try {
      return await callback();
    } on TimeoutException catch (e) {
      if (onTimeout != null) {
        onTimeout();
      } else {
        throw RetryableException(e);
      }
    } on SocketException catch (e) {
      throw RetryableException(e);
    } on RetryableException {
      if (waitTime <= maxWaitTime) {
        await Future.delayed(waitTime);
        continue;
      }

      throw FirebaseStorageException._fromCode(
        StorageErrorCode.retryLimitExceeded,
      );
    } on FirebaseStorageException {
      rethrow;
    } catch (e, stackTrace) {
      throw FirebaseStorageException._unknown(stackTrace);
    }
  }
}

class RetryableException implements Exception {
  final Object reason;

  RetryableException(this.reason);
}

class RetryableResponseErrorCode {
  final int code;
  const RetryableResponseErrorCode(this.code);
}
