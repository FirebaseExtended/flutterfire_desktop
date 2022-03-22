// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls, require_trailing_commas

import 'dart:convert';

/// Multiplication factor to convert seconds to milliseconds.
/// Time comes from Google's Identity Toolkit API as seconds, multiply by this
/// factor then use `fromMillisecondsSinceEpoch` to get a [DateTime] object.
const secondToMilliesecondsFactor = 1000;

/// Decoded Firebase auth JWT token.
class DecodedToken {
  /// Construct a decoded Firebase auth JWT token.
  DecodedToken({
    required this.token,
    required this.header,
    required this.claims,
    required this.data,
    this.signature,
  });

  /// Return the decoded fields from a Firebase auth JWT string token.
  factory DecodedToken.fromJWTString(String token) {
    String? _decodeBase64(String str) {
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

    final parts = token.split('.');

    final header =
        json.decode(_decodeBase64(parts[0]) ?? '') as Map<String, dynamic>;
    final claims =
        json.decode(_decodeBase64(parts[1]) ?? '') as Map<String, dynamic>;
    final signature = parts[2];
    final data = claims['d'] ?? <String, dynamic>{};

    claims.remove('d');

    return DecodedToken(
      token: token,
      header: header,
      claims: claims,
      data: data,
      signature: signature,
    );
  }

  /// The original encoded JWT token.
  final String token;

  /// JWT token headers.
  final Map<String, dynamic> header;

  /// JWT token claims, including both Firebase reserved and optional claims.
  final Map<String, dynamic> claims;

  /// Any additional data encoded with teh claims.
  final Map<String, dynamic> data;

  /// JWT token signature if any.
  final String? signature;

  /// Decodes a Firebase auth token and checks the validity of its time-based claims.
  /// Will return true if the token is within the time window authorized
  /// by the 'nbf' (not-before) and 'iat' (issued-at) claims.
  bool get isValidTimestamp {
    final now =
        (DateTime.now().millisecondsSinceEpoch / secondToMilliesecondsFactor)
            .floor();
    var validSince = 0;
    var validUntil = 0;

    if (claims.containsKey('nbf')) {
      validSince = claims['nbf'] as int;
    } else if (claims.containsKey('iat')) {
      validSince = claims['iat'] as int;
    }

    if (claims.containsKey('exp')) {
      validUntil = claims['exp'] as int;
    } else {
      // token will expire after 24h by default
      validUntil = validSince + 86400;
    }

    return now >= validSince && now <= validUntil;
  }
}
