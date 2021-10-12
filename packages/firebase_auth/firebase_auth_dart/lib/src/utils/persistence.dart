import 'dart:convert';
import 'dart:io';

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
      (Platform.environment['HOME'] ?? Platform.environment['LOCALAPPDATA'])!;

  File get _file => File('$_home/$name.json');

  /// Store the key-value pair in the box with [name], if key already
  /// exists the value will be overwritten.
  Future<void> putValue(String key, T? value) async {
    if (!_file.existsSync()) {
      await _file.create();
    }

    final content = await _file.readAsString();
    final contentMap = {};

    if (content.isNotEmpty) {
      final Map<String, dynamic> jsonFromString = jsonDecode(content);
      contentMap.addAll(jsonFromString);
    }

    if (value != null) {
      contentMap[key] = value;
    } else {
      contentMap.remove(key);
    }

    final file = await _file.open(mode: FileMode.writeOnly);

    if (contentMap.isNotEmpty) {
      await file.writeString(jsonEncode(contentMap));
    } else {
      await _file.delete();
    }
    await file.close();
  }

  /// Get the value for a specific key, if no such key exists, or no such box with [name]
  /// [StorageBoxException] will be thrown.
  Future<T> getValue(String key) async {
    try {
      final content = await _file.readAsString();

      final Map<String, dynamic> toJson = jsonDecode(content);
      if (!toJson.containsKey(key)) {
        throw StorageBoxException('Key $key does not exist.');
      }
      return toJson[key];
    } on FileSystemException {
      throw StorageBoxException('Box $name does not exist.');
    }
  }
}

/// Throw when there's an error with [StorageBox] methods.
class StorageBoxException implements Exception {
  // ignore: public_member_api_docs
  StorageBoxException([this.message]);

  /// Message describing the error.
  final String? message;
}
