import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'exception.dart';
import 'user.dart';

// TODO(Mais): if this will only have API key, remove it and use a simpler way.

/// The settings of this instance of IPAuth package.
class IPAuthSettings {
  /// Default constructor.
  IPAuthSettings({
    required this.apiKey,
  });

  /// The Web API key either from a GCP project or a Firebase project.
  late final String apiKey;
}

/// Pure Dart service wrapper around the Identity Platform REST API.
///
/// https://cloud.google.com/identity-platform/docs/use-rest-api
class IPAuth {
  /// Default constructor.
  IPAuth({required this.settings}) {
    _endpoint = IPEndpoint(settings.apiKey);
  }

  /// The settings this instance is configured with.
  late IPAuthSettings settings;
  late IPEndpoint _endpoint;

  /// Sign users in using email and password.
  Future<IPUser> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final _userMap = await _makeRequest(
        _endpoint.signInWithEmailAndPassword,
        {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );
      return IPUser.fromJson(_userMap);
    } catch (exception) {
      log('$exception', name: 'IPAuth/signInWithEmailAndPassword');

      rethrow;
    }
  }

  /// Sign users up using email and password.
  Future<IPUser> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final _userMap = await _makeRequest(
        _endpoint.signUpWithEmailAndPassword,
        {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );
      return IPUser.fromJson(_userMap);
    } catch (exception) {
      log('$exception', name: 'IPAuth/signUpWithEmailAndPassword');

      rethrow;
    }
  }

  /// Helper function to construct a request and throw on errors.
  Future<Map<String, dynamic>> _makeRequest(
      Uri url, Map<String, dynamic> body) async {
    final _response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (_response.statusCode == 200) {
      final _bodyMap = jsonDecode(_response.body);
      return _bodyMap;
    } else {
      // ignore: avoid_dynamic_calls
      final String errorCode = jsonDecode(_response.body)['error']['message'];
      throw IPException.fromErrorCode(errorCode);
    }
  }
}

/// Endpoints wrapper.
class IPEndpoint {
  /// Default constructor.
  IPEndpoint(this.apiKey);

  /// The API Key used for requests with this Endpoint instance.
  final String apiKey;

  static const String _scheme = 'https';
  static const String _host = 'identitytoolkit.googleapis.com';
  static const String _apiVersion = 'v1';

  Uri _baseUrl(String? endpoint) => Uri(
        scheme: _scheme,
        host: _host,
        pathSegments: [
          _apiVersion,
          endpoint!,
        ],
        queryParameters: {
          'key': apiKey,
        },
      );

  static const Map<String, String> _endpoints = {
    'signInWithEmailAndPassword': 'accounts:signInWithPassword',
    'signUp': 'accounts:signUp',
  };

  /// Get the Uri representation of signInWithEmailAndPassword endpoint
  /// as per IP REST API documentation.
  ///
  /// https://cloud.google.com/identity-platform/docs/use-rest-api#section-sign-in-email-password
  Uri get signInWithEmailAndPassword {
    return _baseUrl(_endpoints['signInWithEmailAndPassword']);
  }

  /// Get the Uri representation of signUp endpoint
  /// as per IP REST API documentation.
  ///
  /// https://cloud.google.com/identity-platform/docs/use-rest-api#section-create-email-password
  Uri get signUpWithEmailAndPassword {
    return _baseUrl(_endpoints['signUp']);
  }
}
