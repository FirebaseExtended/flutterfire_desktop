part of firebase_auth_dart;

/// A storage box is a container for key-value pairs of data
/// which exists in one box with specific name.
///
/// To get or create a new box, first initialize an instance
/// with a name, then use the methods provided for that box,
/// if the box doesn't exist, it will be created, if it exists
/// data will be written to the existing one.
class StorageBox<T extends Object> {
  // ignore: public_member_api_docs
  StorageBox(this.name);

  /// The name of the box which you want to create or get.
  final String name;

  final _home =
      (Platform.environment['HOME'] ?? Platform.environment['APPDATA'])!;
  File get _getFile => File(
      '$_home${Platform.pathSeparator}.firebase-auth${Platform.pathSeparator}$name.json');

  late RandomAccessFile _file;

  /// Store the key-value pair in the box with [name], if key already
  /// exists the value will be overwritten.
  void putValue(String key, T? value) {
    if (!_getFile.existsSync()) {
      _getFile.createSync(recursive: true);
    }
    final contentMap = Map.from(_readFile(FileMode.append));

    if (value != null) {
      contentMap[key] = value;
    } else {
      contentMap.remove(key);
    }

    _file = _getFile.openSync(mode: FileMode.writeOnly);
    _file.writeStringSync(jsonEncode(contentMap));
  }

  /// Get the value for a specific key, if no such key exists, or no such box with [name]
  /// [StorageBoxException] will be thrown.
  T getValue(String key) {
    try {
      final contentText = _getFile.readAsStringSync();
      final Map<String, dynamic> content = jsonDecode(contentText);

      if (!content.containsKey(key)) {
        throw StorageBoxException('Key $key does not exist.');
      }

      return content[key];
    } on FileSystemException {
      throw StorageBoxException('Box $name does not exist.');
    }
  }

  Map<String, dynamic> _readFile(FileMode mode) {
    _file = _getFile.openSync(mode: mode);
    final length = _file.lengthSync();
    _file.setPositionSync(0);

    final buffer = Uint8List(length);
    _file.readIntoSync(buffer);
    _file.closeSync();

    final contentText = utf8.decode(buffer);

    if (contentText.isEmpty) {
      return {};
    }

    final content = json.decode(contentText) as Map<String, dynamic>;

    return content;
  }
}

/// Throw when there's an error with [StorageBox] methods.
class StorageBoxException implements Exception {
  // ignore: public_member_api_docs
  StorageBoxException([this.message]);

  /// Message describing the error.
  final String? message;
}
