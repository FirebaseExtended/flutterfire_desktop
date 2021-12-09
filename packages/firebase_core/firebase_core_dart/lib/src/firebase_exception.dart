// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// A generic class which provides exceptions in a Firebase-friendly format
/// to users.
///
/// ```dart
/// try {
///   await Firebase.initializeApp();
/// } on FirebaseException catch (e) {
///   print(e.toString());
/// }
/// ```
@immutable
class FirebaseException implements Exception {
  /// A generic class which provides exceptions in a Firebase-friendly format
  /// to users.
  ///
  /// ```dart
  /// try {
  ///   await Firebase.initializeApp();
  /// } catch (e) {
  ///   print(e.toString());
  /// }
  /// ```
  FirebaseException({
    required this.plugin,
    this.message,
    this.code = 'unknown',
    this.stackTrace,
  });

  /// The plugin the exception is for.
  ///
  /// The value will be used to prefix the message to give more context about
  /// the exception.
  final String plugin;

  /// The long form message of the exception.
  final String? message;

  /// The optional code to accommodate the message.
  ///
  /// Allows users to identify the exception from a short code-name, for example
  /// "no-app" is used when a user attempts to read a [`FirebaseApp`] which does
  /// not exist.
  final String code;

  /// The stack trace which provides information to the user about the call
  /// sequence that triggered an exception
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FirebaseException) {
      return false;
    }
    return other.hashCode == hashCode;
  }

  @override
  int get hashCode => Object.hash(plugin, code, message);

  @override
  String toString() {
    var output = '[$plugin/$code] $message';

    if (stackTrace != null) {
      output += '\n\n${stackTrace.toString()}';
    }

    return output;
  }
}
