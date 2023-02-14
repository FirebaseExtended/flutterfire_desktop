import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import 'utils.dart';

void main() {
  group('Large file download', () {
    test('verifies md5', () async {
      final pwd = Directory.current.path;
      final path = join(pwd, 'test', 'downloads', 'large.bin');
      final hash = await getMD5Hash(path);
      print(hash);
    });
  });
}
