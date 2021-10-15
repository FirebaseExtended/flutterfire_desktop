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
  File get _getFile =>  File('$_home${Platform.pathSeparator}$name.json');

  late RandomAccessFile _file;

  /// Store the key-value pair in the box with [name], if key already
  /// exists the value will be overwritten.
  Future<void> putValue(String key, T? value) async {
    final contentMap = Map.from(await _readFile(FileMode.append));

    if (value != null) {
      contentMap[key] = value;
    } else {
      contentMap.remove(key);
    }

    if (contentMap.isNotEmpty) {
      _file = await _getFile.open(mode: FileMode.writeOnly);
      await _file.writeString(jsonEncode(contentMap));
    } else {
      await _getFile.delete();
    }
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

  Future<Map<String, dynamic>> _readFile(FileMode mode) async {
    _file = await _getFile.open(mode: mode);
    final length = await _file.length();
    _file = await _file.setPosition(0);

    final buffer = Uint8List(length);
    await _file.readInto(buffer);
    await _file.close();

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
