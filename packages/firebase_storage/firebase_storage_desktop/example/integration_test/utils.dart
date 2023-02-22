import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:http/http.dart' as http;

StreamChannel<String> createHttpChannel(Uri uri) {
  final client = http.Client();
  final responses = StreamController<String>.broadcast();
  final requests = StreamController<String>();

  const headers = {'Content-Type': 'application/json'};

  requests.stream.listen((event) async {
    try {
      final res = await client.post(uri, body: event, headers: headers);
      responses.add(res.body);
    } catch (e) {
      responses.addError(e);
    }
  });

  return StreamChannel.withGuarantees(responses.stream, requests);
}

final channel = createHttpChannel(Uri.parse('http://localhost:4040/json-rpc'));
final rpcClient = Client(channel)..listen();

Future<void> clearStorage() {
  return rpcClient.sendRequest('clearStorage');
}

Future<void> putString(String path, String content) {
  return rpcClient.sendRequest('putString', {'path': path, 'content': content});
}

Future<void> verifyExists(String path) {
  return rpcClient.sendRequest('verifyExists', {'path': path});
}

Future<void> verifyMD5Hash(String path, String hash) {
  return rpcClient.sendRequest('verifyMD5Hash', {'path': path, 'hash': hash});
}

Matcher fileNotExists(String path) {
  return predicate((e) {
    if (e is! RpcException) return false;
    return e.message == 'File $path does not exist';
  });
}

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
