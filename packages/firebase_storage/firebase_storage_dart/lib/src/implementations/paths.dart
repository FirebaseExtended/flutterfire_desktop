String? parent(String path) {
  if (path.isEmpty) {
    return null;
  }
  final index = path.lastIndexOf('/');
  if (index == -1) {
    return '';
  }
  return path.substring(0, index);
}

String child(String path, String childPath) {
  final canonicalChildPath = childPath.split('/')
    ..retainWhere((element) => element.isNotEmpty);
  final joinedCanonicalChildPath = canonicalChildPath.join('/');
  if (path.isEmpty) {
    return joinedCanonicalChildPath;
  } else {
    return path + '/' + joinedCanonicalChildPath;
  }
}

///
///Returns the last component of a path.
///'/foo/bar' -> 'bar'
///'/foo/bar/baz/' -> 'baz/'
///'/a' -> 'a'
///
String lastComponent(String path) {
  final index = path.lastIndexOf('/', path.length - 2);
  if (index == -1) {
    return path;
  } else {
    return path.substring(index + 1);
  }
}
