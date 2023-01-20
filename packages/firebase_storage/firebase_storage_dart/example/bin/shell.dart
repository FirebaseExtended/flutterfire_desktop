import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart_example/firebase_options.dart';

void main(List<String> arguments) async {
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

  final storage = FirebaseStorage.instance;

  try {
    final value = await storage.ref('flutter-tests').list();
    print(value.prefixes.map((e) => e.name));
    print(value.items.map((e) => e.name));

    final downloadUrl = await value.items[0].getDownloadURL();
    print(downloadUrl);
  } catch (err) {
    print(err);
  }

  try {
    final snapshot = await storage
        .ref('writeOnly.txt')
        .putData(Uint8List.fromList(utf8.encode('hello world')));

    print(snapshot);
  } catch (err) {
    print(err);
  }

  try {
    await storage.ref('forbidden.txt').putString('can I write this?');
    print('Should never be called');
    exit(-1);
  } catch (err) {
    print(err);
  }

  final jsonMeta = SettableMetadata(contentType: 'application/json');

  try {
    final snapshot = await storage
        .ref('flutter-tests/test-string.json')
        .putString('{"test": "test"}', metadata: jsonMeta);

    print(snapshot);
  } catch (err) {
    print(err);
  }

  try {
    final snapshot = await storage
        .ref('flutter-tests/test-string.json')
        .putData(Uint8List.fromList(utf8.encode('{"test": "test"}')), jsonMeta);

    print(snapshot);
  } catch (err) {
    print(err);
  }

  // final storage = FirebaseStorage.instance;
  // final shell = StorageShell(storage, storage.ref('/'));
  // stdout.write(shell);

  // while (true) {
  //   final command = shell.prompt();
  //   final out = await command.execute();
  //   stdout.write(out);
  // }
}
