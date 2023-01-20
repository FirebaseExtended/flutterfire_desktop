part of firebase_storage_dart;

enum StorageErrorCode {
  unknown('unknown', 'An unknown error occurred'),
  objectNotFound(
    'object-not-found',
    'No object exists at the desired reference.',
  ),
  bucketNotFound(
    'bucket-not-found',
    'No bucket is configured for Firebase Storage.',
  ),
  projectNotFound(
    'project-not-found',
    'No project is configured for Firebase Storage.',
  ),
  quotaExceeded(
    'quota-exceeded',
    'Quota on your Firebase Storage bucket has been exceeded.',
  ),
  unauthenticated(
    'unauthenticated',
    'User is unauthenticated. Authenticate and try again.',
  ),
  unauthorized(
    'unauthorized',
    'User is not authorized to perform the desired action.',
  ),
  retryLimitExceeded(
    'retry-limit-exceeded',
    'The maximum time limit on an operation (upload, download, delete, etc.) '
        'has been exceeded.',
  ),
  invalidChecksum(
    'invalid-checksum',
    'File on the client does not match the checksum of the file received by the server.',
  ),
  canceled('canceled', 'User cancelled the operation.');

  const StorageErrorCode(this.code, this.message);

  final String code;
  final String message;
}

class FirebaseStorageException extends FirebaseException {
  FirebaseStorageException._({
    required super.plugin,
    super.code = 'unknown',
    super.message = 'An unknown error occurred',
    super.stackTrace,
  });

  factory FirebaseStorageException._fromCode(
    StorageErrorCode code, [
    StackTrace? stackTrace,
  ]) {
    return FirebaseStorageException._(
      plugin: 'firebase_storage',
      code: code.code,
      message: code.message,
      stackTrace: stackTrace,
    );
  }

  factory FirebaseStorageException._unknown([StackTrace? stackTrace]) {
    return FirebaseStorageException._(
      plugin: 'firebase_storage',
      stackTrace: stackTrace,
    );
  }

  factory FirebaseStorageException._fromHttpStatusCode(
    int code, [
    StackTrace? stackTrace,
  ]) {
    switch (code) {
      case 401:
        return FirebaseStorageException._fromCode(
          StorageErrorCode.unauthenticated,
          stackTrace,
        );
      case 403:
        return FirebaseStorageException._fromCode(
          StorageErrorCode.unauthorized,
          stackTrace,
        );

      default:
        return FirebaseStorageException._unknown(stackTrace);
    }
  }
}

Future<T> asyncGuard<T>(Future<T> Function() callback) async {
  try {
    return await callback();
  } on FirebaseStorageException {
    rethrow;
  } catch (e, stackTrace) {
    throw FirebaseStorageException._unknown(stackTrace);
  }
}
