import 'dart:convert';
import 'dart:io';

/// A storage box is a container for key-value pairs of data
/// which exists in one box with specific name.
///
/// To get or create a new box, first initialize an instance
/// with a name, then use the methods provided for that box,
/// if the box doesn't exist, it will be created, if it exists
/// data will be written to the existing one.
class StorageBox {
  // ignore: public_member_api_docs
  StorageBox(this.name);

  /// The name of the box which you want to create or get.
  final String name;

  final _home =
      (Platform.environment['HOME'] ?? Platform.environment['APPDATA'])!;

  File get _file => File('$_home/$name.json');

  Future<void> putValue(String key, String value) async {
    final content = await _file.readAsString();
    final contentMap = {};

    if (content.isNotEmpty) {
      final Map<String, dynamic> jsonFromString = jsonDecode(content);
      contentMap.addAll(jsonFromString);
    }

    contentMap[key] = value;

    final file = await _file.open(mode: FileMode.writeOnly);

    await file.writeString(jsonEncode(contentMap));

    await file.close();
  }

  Future<String> getValue(String key) async {
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
