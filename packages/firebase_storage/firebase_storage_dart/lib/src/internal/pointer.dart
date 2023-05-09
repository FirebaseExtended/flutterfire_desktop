/// Internal helper class used to manage storage reference paths.
class Pointer {
  /// Constructs a new [Pointer] with a given path.
  Pointer(String? path) : _path = path ?? '/' {
    if (_path.isEmpty) {
      _path = '/';
    } else {
      String _parsedPath = _path;

      // Remove trailing slashes
      if (_path.length > 1 && _path.endsWith('/')) {
        _parsedPath = _parsedPath.substring(0, _parsedPath.length - 1);
      }

      // Remove starting slashes
      if (_path.startsWith('/') && _path.length > 1) {
        _parsedPath = _parsedPath.substring(1, _parsedPath.length);
      }

      _path = _parsedPath;
    }
  }

  String _path;

  /// Returns whether the path points to the root of a bucket.
  bool get isRoot {
    return path == '/';
  }

  /// Returns the serialized path.
  String get path {
    return _path;
  }

  /// Returns the name of the path.
  ///
  /// For example, a paths "foo/bar.jpg" name is "bar.jpg".
  String get name {
    return path.split('/').last;
  }

  /// Returns the parent path.
  ///
  /// If the current path is root, `null` wil be returned.
  String? get parent {
    if (isRoot) {
      return null;
    }

    List<String> chunks = path.split('/');
    chunks.removeLast();
    return chunks.join('/');
  }

  /// Returns a child path relative to the current path.
  String child(String childPath) {
    Pointer childPointer = Pointer(childPath);

    // If already at
    if (isRoot) {
      return childPointer.path;
    }

    return '$path/${childPointer.path}';
  }
}
