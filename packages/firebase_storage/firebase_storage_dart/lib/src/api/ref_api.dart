part of api;

/// Class wrapping methods that calls to the following endpoints:
/// - `securetoken.googleapis.com`: refresh a Firebase ID token.
@internal
class RefApi extends APIDelegate {
  // ignore: public_member_api_docs
  RefApi(API api) : super(api);

  /// Refresh a user's IdToken using a `refreshToken`,
  /// will refresh even if the token hasn't expired.
  ///
  /// Common error codes:
  /// - `TOKEN_EXPIRED`: The user's credential is no longer valid. The user must sign in again.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  /// - `USER_NOT_FOUND`: The user corresponding to the refresh token was not found. It is likely the user was deleted.
  /// - `INVALID_REFRESH_TOKEN`: An invalid refresh token is provided.
  /// - `INVALID_GRANT_TYPE`: the grant type specified is invalid.
  /// - `MISSING_REFRESH_TOKEN`: no refresh token provided.
  /// - API key not valid. Please pass a valid API key. (invalid API key provided)
  Future<String?> refreshIdToken(String? refreshToken) async {
    try {
      return await _exchangeRefreshWithIdToken(refreshToken);
    } catch (_) {
      rethrow;
    }
  }

  Future<String?> _exchangeRefreshWithIdToken(String? refreshToken) async {
    final baseUri = api.apiConfig.emulator != null
        ? 'http://${api.apiConfig.emulator!.host}:${api.apiConfig.emulator!.port}'
            '/securetoken.googleapis.com/v1/'
        : 'https://securetoken.googleapis.com/v1/';

    final _response = await http.post(
      Uri.parse(
        '${baseUri}token?key=${api.apiConfig.apiKey}',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/json'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);

    return _data['access_token'];
  }

  Future getRefListData(
      {ListOptions? options, required Reference reference}) async {
    final urlPart = reference.location.bucketOnlyServerUrl();
    final url = makeUrl(urlPart, reference.storage.host, "https");
    final urlparams = ReferenceListRessultRequestArgument(
            location: reference.location,
            delimiter: '/',
            pageToken: options?.pageToken,
            maxResults: options?.maxResults)
        .toJson();
    final requestOptions =HttpsCallableOptions(method: RequestMethod.get,
  timeout: reference.storage.maxOperationRetryTime,
  url:url,
  queryParam:urlparams );

  listHandler(service, location.bucket),
  
  
  requestInfo.errorHandler = sharedErrorHandler(location);
  // return requestInfo;
    // if (!this._deleted) {
    // if (1 == 1) {
    //   //parse respone
    //   final auth = FirebaseAuth.instanceFor(app: storage.app);
    //   String? authToken;
    //   if (auth.currentUser != null) {
    //     authToken = await auth.currentUser!.getIdToken();
    //   }
    //   final response = await http.get(Uri.parse('url'), headers: {
    //     // if (appCheckToken != null)
    //     // 'X-Firebase-AppCheck': '$appCheckToken'
    //     'X-Firebase-GMPID': storage.app.options.appId,
    //     'X-Firebase-Storage-Version':
    //         'webjs/' + (firebaseVersion ?? 'AppManager'),
    //     if (authToken != null && authToken.isNotEmpty)
    //       'Authorization': 'Firebase ' + authToken
    //   }).timeout(Duration(milliseconds: storage.maxOperationRetryTime),
    //       onTimeout: () {
    //     throw Exception();
    //   });
    //   if (response.statusCode == 200) {
    //     // print(response.body);
    //     try {
    //       final data = jsonDecode(response.body);

    //       return ListResult(
    //           storage,
    //           data['nextPageToken'],
    //           (data['items'] as List).map((e) => e['name'] as String).toList(),
    //           (data['prefixes'] as List<String>).map((String e) {
    //             final s = e.endsWith('/');
    //             if (s) {
    //               return e.substring(0, e.length - 1);
    //             }
    //             return e;
    //           }).toList());
    //     } on Exception catch (e) {
    //       throw Exception();
    //     }
    //   } else {
    //     throw Exception();
    //   }
    // } else {
    //   return FailRequest(appDeleted());
    // }
  }

  Future delete({required Reference reference}) {
    throw UnimplementedError();
  }

  Future getDownloadURL({required Reference reference}) {
    throw UnimplementedError();
  }

  Future getMetaData({required Reference reference}) {
    final urlPart = reference.location.fullServerUrl();
  final url = makeUrl(urlPart, reference.storage.host, reference.storage.protocol);
  final requestInfo =HttpsCallableOptions(method: RequestMethod.get,
  timeout: reference.storage.maxOperationRetryTime,
  url:url, );
    throw UnimplementedError();
  }

  Future<Uint8List?> getData({required Reference reference, required maxSize}) {
    throw UnimplementedError();
  }

  putData(
      {required Reference reference,
      required Uint8List data,
      SettableMetadata? metadata}) {
    throw UnimplementedError();
  }

  putFile(
      {required Reference reference,
      required File file,
      SettableMetadata? metadata}) {
    throw UnimplementedError();
  }

  putBlob(
      {required Reference reference,
      required dynamic blob,
      SettableMetadata? metadata}) {
    throw UnimplementedError();
  }

  putString(
      {required Reference reference,
      required String data,
      required PutStringFormat format,
      SettableMetadata? metadata}) {
    throw UnimplementedError();
  }

  updateMetadata(
      {required Reference reference, required SettableMetadata metadata}) {
    throw UnimplementedError();
  }

  writeToFile({required Reference reference, required File file}) {
    throw UnimplementedError();
  }
}

/// A [StorageRequest] instance that lets you call a cloud function.
class StorageRequest {
  /// Creates an StorageRequest
  @visibleForTesting
  StorageRequest({
    required this.app,
    required this.origin,
    required this.options,
    required http.Client client,
  }) : _client = client;

  /// The [FirebaseApp] this function belongs to
  final FirebaseApp app;

  /// Configuration options for timeout
  final HttpsCallableOptions options;

  /// Origin specifies a different origin in the case of emulators.
  @visibleForTesting
  final String? origin;

  /// The Http Client used for making requests
  final http.Client _client;

  Future<http.Response> makeRequest() async {
    switch (options.method) {
      case RequestMethod.get:
        return get();
      case RequestMethod.post:
        return post();
      case RequestMethod.delete:
        return delete();
      case RequestMethod.patch:
        return patch();
    }
  }

  Future callRequest() async {
    await addHeaders();
    await makeRequest();
  }

  Future<void> addHeaders() async {
    options.headers ??= {};
    // add auth headers
    final auth = FirebaseAuth.instanceFor(app: app);
    if (auth.currentUser != null) {
      final authToken = await auth.currentUser!.getIdToken();
      options.headers!['Authorization'] = authToken;
    }
    // add version headers
    options.headers!['X-Firebase-Storage-Version'] =
        'webjs/' + (firebaseVersion ?? 'AppManager');
    // add APP ID header
    options.headers!.addAll({'X-Firebase-GMPID': app.options.appId});
    // add app check token header //TODO
    options.headers!.addAll({'X-Firebase-AppCheck': app.options.appId});
  }

  /// Calls the function with the given data.
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    assert(_debugIsValidParameterType(data), 'data must be json serialized');
    String encodedData;
    try {
      encodedData = json.encode({'data': data});
    } catch (e, st) {
      throw FirebaseStorageException(
        //TODO
        StorageErrorCode.APP_DELETED,
        message: 'Data was not json encodeable',
        // code: 'internal',
        // details:
        //     '${options.timeout} millisecond timeout occurred on request to $_url with $data',
        // stackTrace: st,
      );
    }

    try {
      final response = await makeRequest();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> body;
        try {
          body = json.decode(response.body.isEmpty ? '{}' : response.body)
              as Map<String, dynamic>;
        } catch (e, st) {
          throw FirebaseStorageException(
            //TODO

            StorageErrorCode.APP_DELETED,
            message: 'Failed to parse json response',
            // code: 'internal',
            // details: 'Result body from http call was ${response.body}',
            // stackTrace: st,
          );
        }
        if (!body.containsKey('data') && !body.containsKey('result')) {
          throw FirebaseStorageException(
            //TODO
            StorageErrorCode.APP_DELETED,
            message: 'Response is missing data field',
            // code: 'internal',
            // details: 'Result body from http call was ${response.body}',
          );
        }
        // Result is for backwards compatibility
        final result = body['data'] ?? body['result'];

        return HttpsCallableResult(result);
      } else {
        Map<String, dynamic> details;
        try {
          details = json.decode(response.body);
        } catch (e) {
          // fine if we can't parse explicit error data
          details = {'details': response.body};
        }
        throw _errorForResponse(
          response.statusCode,
          details,
        );
      }
    } on TimeoutException catch (e, st) {
      throw FirebaseStorageException(
        //TODO
        StorageErrorCode.APP_DELETED,
        message: 'Firebase functions timeout',
        // code: 'timeout',
        // details:
        //     '${options.timeout} millisecond timeout occurred on request to $_url with $encodedData',
        // stackTrace: st,
      );
    }
  }

  Future<http.Response> post() async {
    return await _client
        .post(
            Uri.parse(options.url).replace(queryParameters: options.queryParam),
            headers: options.headers,
            body: options.body)
        .timeout(Duration(milliseconds: options.timeout));
  }

  Future<http.Response> get<T>() async {
    return await _client
        .get(
          Uri.parse(options.url).replace(queryParameters: options.queryParam),
          headers: options.headers,
        )
        .timeout(Duration(milliseconds: options.timeout));
  }

  Future<http.Response> patch<T>() async {
    return await _client
        .patch(
            Uri.parse(options.url).replace(queryParameters: options.queryParam),
            headers: options.headers,
            body: options.body)
        .timeout(Duration(milliseconds: options.timeout));
  }

  Future<http.Response> delete<T>() async {
    return await _client
        .delete(
            Uri.parse(options.url).replace(queryParameters: options.queryParam),
            headers: options.headers,
            body: options.body)
        .timeout(Duration(milliseconds: options.timeout));
  }
}

/// The result of calling a HttpsCallable function.
class HttpsCallableResult<T> {
  /// Creates a new [HttpsCallableResult]
  HttpsCallableResult(this._data);

  final T _data;

  /// Returns the data that was returned from the Callable HTTPS trigger.
  T get data {
    return _data;
  }
}

/// Options for configuring the behavior of a firebase cloud function
class HttpsCallableOptions {
  /// Options for configuring the behavior of a firebase cloud function
  HttpsCallableOptions(
      {required this.url,
      this.successCodes,
      required this.method,
      this.headers,
      this.queryParam,
      this.body,
      required this.timeout});

  /// The timeout for the function call
  final int timeout;
  final Map<String, dynamic>? queryParam;
  Map<String, String>? headers;
  List<int>? successCodes;
  final RequestMethod method;
  final String url;
  final dynamic body;
}

/// Whether a given call parameter is a valid type.
bool _debugIsValidParameterType(dynamic parameter, [bool isRoot = true]) {
  if (parameter is List) {
    for (final element in parameter) {
      if (!_debugIsValidParameterType(element, false)) {
        return false;
      }
    }
    return true;
  }

  if (parameter is Map) {
    for (final key in parameter.keys) {
      if (key is! String) {
        return false;
      }
    }
    for (final value in parameter.values) {
      if (!_debugIsValidParameterType(value, false)) {
        return false;
      }
    }
    return true;
  }

  return parameter == null ||
      parameter is String ||
      parameter is num ||
      parameter is bool;
}

enum RequestMethod { get, post, delete, patch }
