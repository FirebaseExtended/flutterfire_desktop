/// Support for Firebase authentication methods
/// with pure dart implmentation.
///
library flutterfire_functions_dart;

import 'dart:convert';
import 'package:flutterfire_core_dart/flutterfire_core_dart.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// A [FirebaseFunctions] instance that provides an [httpsCallable] interface
/// for accessing the Firebase Functions API.
class FirebaseFunctions {
  /// Creates Firebase Functions
  @visibleForTesting
  FirebaseFunctions({required this.app, this.region = defaultRegion});

  /// Gets the [FirebaseFunctions] instance for the given [app] and [region].
  factory FirebaseFunctions.instanceFor({
    FirebaseApp? app,
    String region = defaultRegion,
  }) {
    final _app = app ?? Firebase.app();
    if (_instances[_app] == null) {
      _instances[_app] = {};
    }
    if (_instances[_app]![region] == null) {
      _instances[_app]![region] = FirebaseFunctions(app: _app, region: region);
    }
    return _instances[_app]![region]!;
  }

  /// The default region to use for the Firebase Functions API.
  static const defaultRegion = 'us-central1';
  static final Map<FirebaseApp, Map<String, FirebaseFunctions>> _instances = {};

  /// Gets the [FirebaseFunctions] instance for the default app
  // ignore: prefer_constructors_over_static_methods
  static FirebaseFunctions get instance {
    return FirebaseFunctions.instanceFor(app: Firebase.app());
  }

  /// The [FirebaseApp] instance used to create this [FirebaseFunctions] instance.
  final FirebaseApp app;

  /// The region to use for accessing functions
  final String region;

  // The origin used for the functions url, overriden for the emulator suite
  String? _origin;

  /// Http client used for making requests
  http.Client _client = http.Client();

  /// Creates an [HttpsCallable] instance to access a particular cloud function
  HttpsCallable httpsCallable(
    String name, {
    HttpsCallableOptions options = HttpsCallableOptions.defaultOptions,
  }) {
    assert(name.isNotEmpty, 'HttpsCallable name must not be an empty string');
    return HttpsCallable(
      origin: _origin,
      app: app,
      region: region,
      name: name,
      options: options,
      client: _client,
    );
  }

  /// Sets the Http Client used for making request for testing
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void setApiClient(http.Client client) {
    _client = client;
  }

  /// Enables the functions emulator
  void useFunctionsEmulator(String host, int port) {
    _origin = 'http://$host:$port';
  }
}

/// A [HttpsCallable] instance that lets you call a cloud function.
class HttpsCallable {
  /// Creates an HttpsCallable
  @visibleForTesting
  HttpsCallable({
    required this.app,
    required this.region,
    required this.origin,
    required this.options,
    required this.name,
    required http.Client client,
  }) : _client = client;

  /// The name of the function to call
  final String name;

  /// The [FirebaseApp] this function belongs to
  final FirebaseApp app;

  /// The region this function belongs to
  final String region;

  /// Configuration options for timeout
  final HttpsCallableOptions options;

  /// Origin specifies a different origin in the case of emulators.
  @visibleForTesting
  final String? origin;

  /// The Http Client used for making requests
  final http.Client _client;

  Uri get _url => Uri.parse(
        origin != null
            ? '$origin/${app.options.projectId}/$region/$name'
            : 'https://$region-${app.options.projectId}.cloudfunctions.net/$name',
      );

  /// Calls the function with the given data.
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    assert(_debugIsValidParameterType(data), 'data must be json serialized');
    try {
      final encodedData = json.encode({'data': data});

      try {
        final result = await _client.post(
          _url,
          body: encodedData,
          headers: {
            'Content-Type': 'application/json'
            // TODO: Authorization headers
            // 'Authorization': 'Bearer $authToken',
            // 'Firebase'
          },
        ).timeout(options.timeout);
        try {
          final res = json.decode(result.body.isEmpty ? '{}' : result.body)
              as Map<String, dynamic>;
          if (res['result'] != null) {
            return HttpsCallableResult(res['result']);
          }
          return HttpsCallableResult(res['data']);
        } catch (e, st) {
          // TODO: Specific error for invalid json response
          // ignore: avoid_print
          print('$e, $st');
          rethrow;
        }
      } catch (e, st) {
        // TODO: Specific error for http error
        // ignore: avoid_print
        print('$e, $st');
        rethrow;
      }
    } catch (e, st) {
      // TODO: Specific error for invalid json input
      // ignore: avoid_print
      print('$e, $st');
      rethrow;
    }
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
  const HttpsCallableOptions({this.timeout = const Duration(seconds: 30)});

  /// The default options for creating a [HttpsCallable]
  static const defaultOptions =
      HttpsCallableOptions(timeout: Duration(seconds: 70));

  /// The timeout for the function call
  final Duration timeout;
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
