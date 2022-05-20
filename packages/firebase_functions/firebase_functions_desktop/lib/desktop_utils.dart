// ignore_for_file: require_trailing_commas

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;
import 'package:firebase_core_desktop/firebase_core_desktop.dart';
import 'package:firebase_functions_dart/firebase_functions_dart.dart'
    as functions_dart;

/// Given a [FirebaseApp], a [core_dart.FirebaseApp] is returned.
core_dart.FirebaseApp app([String? name]) {
  return name != null ? core_dart.Firebase.app(name) : core_dart.Firebase.app();
}

/// Given a dart error, a [FirebaseFunctionsException] is returned.
FirebaseFunctionsException convertFirebaseFunctionsException(
    functions_dart.FirebaseFunctionsException exception,
    [StackTrace? stackTrace]) {
  return FirebaseFunctionsException(
    code: exception.code,
    message: exception.message!,
    stackTrace: stackTrace,
    details: exception.details,
  );
}
