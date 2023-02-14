import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

Future<String> getMD5Hash(String filePath) {
  final completer = Completer<String>();
  final file = File(filePath);

  final output = AccumulatorSink<Digest>();
  final input = md5.startChunkedConversion(output);

  file.openRead().listen((event) {
    input.add(event);
  }, onDone: () {
    input.close();
    completer.complete(base64Encode(output.events.single.bytes));
  });

  return completer.future;
}
