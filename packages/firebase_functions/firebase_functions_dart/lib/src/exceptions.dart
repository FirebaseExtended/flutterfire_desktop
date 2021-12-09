// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of '../firebase_functions_dart.dart';

/// Generic exception related to Cloud Functions. Check the error code
/// and message for more details.
class FirebaseFunctionsException extends FirebaseException
    implements Exception {
  // ignore: public_member_api_docs
  @protected
  FirebaseFunctionsException({
    required String message,
    required String code,
    StackTrace? stackTrace,
    this.details,
  }) : super(
          plugin: 'firebase_functions',
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  /// Additional data provided with the exception.
  final dynamic details;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FirebaseFunctionsException) {
      return false;
    }
    return other.message == message &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(plugin, code, message, details);

  @override
  String toString() {
    var output = '[$plugin/$code] $message';
    if (details != null) {
      output += '\n$details';
    }
    if (stackTrace != null) {
      output += '\n\n${stackTrace.toString()}';
    }

    return output;
  }
}

/// Takes an HTTP status code and returns the corresponding ErrorCode.
/// This is the standard HTTP status code -> error mapping defined in:
/// https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto
String codeForHTTPStatus(int status) {
  switch (status) {
    case 0:
      // This can happen if the server returns 500.
      return 'internal';
    case 400:
      return 'invalid-argument';
    case 401:
      return 'unauthenticated';
    case 403:
      return 'permission-denied';
    case 404:
      return 'not-found';
    case 409:
      return 'aborted';
    case 429:
      return 'resource-exhausted';
    case 499:
      return 'cancelled';
    case 500:
      return 'internal';
    case 501:
      return 'unimplemented';
    case 503:
      return 'unavailable';
    case 504:
      return 'deadline-exceeded';
    default:
      return 'unknown';
  }
}

/// Takes an HTTP response and returns the corresponding Error, if any.
FirebaseFunctionsException _errorForResponse(
  int status,
  Map<String, Object?>? bodyJSON,
) {
  var code = codeForHTTPStatus(status);

  // Start with reasonable defaults from the status code.
  var description = code;

  Object? details;

  // Then look through the body for explicit details.
  try {
    final errorJSON = bodyJSON?['error'] as Map<String, Object?>?;
    if (errorJSON != null) {
      final status = errorJSON['status'];
      if (status is String) {
        if (!_errorCodeMap.containsKey(status)) {
          // They must've included an unknown error code in the body.
          return FirebaseFunctionsException(
            code: 'internal',
            message: 'internal',
          );
        }
        code = _errorCodeMap[status]!;

        // The default description needs to be updated for the new code.
        description = status;
      }

      final message = errorJSON['message'];
      if (message is String) {
        description = message;
      }

      details = errorJSON['details'];
      if (details is String) {
        details = json.decode(details);
      }
    }
  } catch (e) {
    // If we couldn't parse explicit error data, that's fine.
  }

  return FirebaseFunctionsException(
    code: code,
    message: description,
    details: details,
  );
}

const _errorCodeMap = {
  'OK': 'ok',
  'CANCELLED': 'cancelled',
  'UNKNOWN': 'unknown',
  'INVALID_ARGUMENT': 'invalid-argument',
  'DEADLINE_EXCEEDED': 'deadline-exceeded',
  'NOT_FOUND': 'not-found',
  'ALREADY_EXISTS': 'already-exists',
  'PERMISSION_DENIED': 'permission-denied',
  'UNAUTHENTICATED': 'unauthenticated',
  'RESOURCE_EXHAUSTED': 'resource-exhausted',
  'FAILED_PRECONDITION': 'failed-precondition',
  'ABORTED': 'aborted',
  'OUT_OF_RANGE': 'out-of-range',
  'UNIMPLEMENTED': 'unimplemented',
  'INTERNAL': 'internal',
  'UNAVAILABLE': 'unavailable',
  'DATA_LOSS': 'data-loss'
};
