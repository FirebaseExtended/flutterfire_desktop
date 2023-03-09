part of firebase_storage_desktop;

T platformErrorCallbackGuard<T>(T Function() callback) {
  try {
    return callback();
  } on core_dart.FirebaseException catch (e, stackTrace) {
    throw FirebaseException(
      plugin: e.plugin,
      code: e.code,
      message: e.message,
      stackTrace: stackTrace,
    );
  }
}

Future<T> platformErrorAsyncGuard<T>(Future<T> Function() callback) {
  return platformErrorFutureGuard(callback());
}

Future<T> platformErrorFutureGuard<T>(Future<T> future) async {
  try {
    return await future;
  } on core_dart.FirebaseException catch (e, stackTrace) {
    throw FirebaseException(
      plugin: e.plugin,
      code: e.code,
      message: e.message,
      stackTrace: stackTrace,
    );
  }
}

void platformErrorGuard(dynamic err, [StackTrace? stackTrace]) {
  if (err is core_dart.FirebaseException) {
    throw FirebaseException(
      plugin: err.plugin,
      code: err.code,
      message: err.message,
      stackTrace: stackTrace,
    );
  } else {
    throw err;
  }
}
