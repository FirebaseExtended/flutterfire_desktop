// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls, require_trailing_commas

import 'dart:convert';

/// Multiplication factor to convert seconds to milliseconds, as time
/// comes from Google's Identity Toolkit as seconds, multiply by this
/// factor then use `fromMillisecondsSinceEpoch` to get a [DateTime] object.
const secondToMilliesecondsFactor = 1000;

/// A utility to decode JSON Web Tokens.
extension DecodeJWT on String {
  /// Get and converty the expiration time from seconds to [DateTime].
  DateTime get expirationTime {
    return DateTime.fromMillisecondsSinceEpoch(
        decodeJWT['exp'] * secondToMilliesecondsFactor);
  }

  /// get a Map from a JWT.
  Map<String, dynamic> get decodeJWT {
    final parts = split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }

    payloadMap['token'] = this;

    return payloadMap;
  }

  String _decodeBase64(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }
}
