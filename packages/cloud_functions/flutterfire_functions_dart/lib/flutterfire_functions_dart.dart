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
  FirebaseFunctions._({required this.app, this.region = _defaultRegion});

  /// Gets the [FirebaseFunctions] instance for the given [app] and [region].
  factory FirebaseFunctions.instanceFor({
    FirebaseApp? app,
    String region = _defaultRegion,
  }) {
    final _app = app ?? Firebase.app();
    if (_instances[_app] == null) {
      _instances[_app] = {};
    }
    if (_instances[_app]![region] == null) {
      _instances[_app]![region] =
          FirebaseFunctions._(app: _app, region: region);
    }
    return _instances[_app]![region]!;
  }

  static const _defaultRegion = 'us-central1';
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

  /// Creates an [HttpsCallable] instance to access a particular cloud function
  HttpsCallable httpsCallable(
    String name, {
    HttpsCallableOptions options = HttpsCallableOptions._defaultOptions,
  }) {
    assert(name.isNotEmpty, 'HttpsCallable name must not be an empty string');
    return HttpsCallable._(
      origin: _origin,
      app: app,
      region: region,
      name: name,
      options: options,
    );
  }

  /// Enables the functions emulator
  void useFunctionsEmulator(String host, int port) {
    _origin = 'http://$host:$port';
  }
}

/// A [HttpsCallable] instance that lets you call a cloud function.
class HttpsCallable {
  HttpsCallable._({
    required this.app,
    required this.region,
    required this.origin,
    required this.options,
    required this.name,
  });

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
        final result = await http.post(
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
            return HttpsCallableResult._(res['result']);
          }
          return HttpsCallableResult._(res['data']);
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
  HttpsCallableResult._(this._data);

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
  static const _defaultOptions =
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
