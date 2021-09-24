import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // Avoid HTTP error 400 mocked returns
    // TODO(pr-Mais): once done create mock clients
    HttpOverrides.global = null;
  });
}
