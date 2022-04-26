enum StorageErrorCode {
  // Shared between all platforms
  UNKNOWN,
  OBJECT_NOT_FOUND,
  BUCKET_NOT_FOUND,
  PROJECT_NOT_FOUND,
  QUOTA_EXCEEDED,
  UNAUTHENTICATED,
  UNAUTHORIZED,
  UNAUTHORIZED_APP,
  RETRY_LIMIT_EXCEEDED,
  INVALID_CHECKSUM,
  CANCELED,
  // JS specific
  INVALID_EVENT_NAME,
  INVALID_URL,
  INVALID_DEFAULT_BUCKET,
  NO_DEFAULT_BUCKET,
  CANNOT_SLICE_BLOB,
  SERVER_FILE_WRONG_SIZE,
  NO_DOWNLOAD_URL,
  INVALID_ARGUMENT,
  INVALID_ARGUMENT_COUNT,
  APP_DELETED,
  INVALID_ROOT_OPERATION,
  INVALID_FORMAT,
  INTERNAL_ERROR,
  UNSUPPORTED_ENVIRONMENT,
}

extension ToString on StorageErrorCode {
  String get asString {
    return name.toLowerCase().replaceAll('_', '-');
  }
}

extension GetMessage on StorageErrorCode {
  String get message {
    switch (this) {
      case StorageErrorCode.OBJECT_NOT_FOUND:
        return "No object exists at the desired reference.";
      case StorageErrorCode.BUCKET_NOT_FOUND:
        return "No bucket is configured for Firebase Storage.";
      case StorageErrorCode.PROJECT_NOT_FOUND:
        return "No project is configured for Firebase Storage.";
      case StorageErrorCode.QUOTA_EXCEEDED:
        return "Quota on your Firebase Storage bucket has been exceeded.";
      case StorageErrorCode.UNAUTHENTICATED:
        return "User is unauthenticated. Authenticate and try again.";
      case StorageErrorCode.UNAUTHORIZED:
        return "User is not authorized to perform the desired action.";
      case StorageErrorCode.RETRY_LIMIT_EXCEEDED:
        return "The maximum time limit on an operation (upload, download, delete, etc.) has been exceeded.";
      case StorageErrorCode.INVALID_CHECKSUM:
        return "File on the client does not match the checksum of the file received by the server.";
      case StorageErrorCode.CANCELED:
        return "User cancelled the operation.";
      case StorageErrorCode.UNKNOWN:
      default:
        {
          return "An unknown error occurred";
        }
    }
  }
}

class StorageError {
  late String _baseMessage;
  String message;
  final StorageErrorCode code;
  /**
   * Stores custom error data unque to StorageError.
   */
  String? _serverResponse;

  ///
  /// @param code - A StorageErrorCode string to be prefixed with 'storage/' and
  /// added to the end of the message.
  /// @param message  - Error message.
  ///
  StorageError(this.code, this.message) {
    _baseMessage = message;
  }

  /// Compares a StorageErrorCode against this error's code, filtering out the prefix.

  bool _codeEquals(StorageErrorCode code) {
    return prependCode(code) == this.code;
  }

  /**
   * Optional response message that was added by the server.
   */
  String? get serverResponse {
    return _serverResponse;
  }

  set serverResponse(String? serverResponse) {
    _serverResponse = serverResponse;
    if (_serverResponse != null) {
      message = '${_baseMessage}\n${_serverResponse}';
    } else {
      message = _baseMessage;
    }
  }
}

String prependCode(StorageErrorCode code) {
  return 'storage/' + code.name;
}

StorageError invalidDefaultBucket(String bucket) {
  return StorageError(StorageErrorCode.INVALID_DEFAULT_BUCKET,
      "Invalid default bucket '" + bucket + "'.");
}

StorageError invalidUrl(String url) {
  return StorageError(
      StorageErrorCode.INVALID_URL, "Invalid URL '" + url + "'.");
}
