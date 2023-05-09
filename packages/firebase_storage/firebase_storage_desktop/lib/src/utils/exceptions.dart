import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Catches a [PlatformException] and returns an [Exception].
///
/// If the [Exception] is a [PlatformException], a [FirebaseException] is returned.
Never convertPlatformException(
  dynamic exception,
  StackTrace stackTrace,
) {
  if (exception is! Exception || exception is! PlatformException) {
    Error.throwWithStackTrace(exception, stackTrace);
  }

  Error.throwWithStackTrace(
    platformExceptionToFirebaseException(exception, stackTrace),
    stackTrace,
  );
}

/// Catches a [PlatformException] and converts it into a [FirebaseException] if
/// it was intentionally caught on the native platform.
Future<T> catchFuturePlatformException<T>(
  Object exception,
  StackTrace stackTrace,
) {
  if (exception is! Exception || exception is! PlatformException) {
    return Future.error(exception, stackTrace);
  }

  return Future<T>.error(
    platformExceptionToFirebaseException(exception, stackTrace),
    stackTrace,
  );
}

/// Converts a [PlatformException] into a [FirebaseException].
///
/// A [PlatformException] can only be converted to a [FirebaseException] if the
/// `details` of the exception exist. Firebase returns specific codes and messages
/// which can be converted into user friendly exceptions.
FirebaseException platformExceptionToFirebaseException(
  PlatformException platformException,
  StackTrace stackTrace,
) {
  Map<String, String>? details = platformException.details != null
      ? Map<String, String>.from(platformException.details)
      : null;

  String code = 'unknown';
  String message = platformException.message ?? '';

  if (details != null) {
    code = details['code'] ?? code;
    message = details['message'] ?? message;
  }

  // TODO(ehesp): Add stack trace support when it lands
  return FirebaseException(
      plugin: 'firebase_storage', code: code, message: message);
}
