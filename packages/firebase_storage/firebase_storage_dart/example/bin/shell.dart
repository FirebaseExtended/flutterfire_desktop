import 'dart:io';

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart_example/firebase_options.dart';
import 'package:firebase_storage_dart_example/firebase_storage_dart_example.dart';

void main(List<String> arguments) async {
  await Firebase.initializeApp(options: firebaseOptions);

  final storage = FirebaseStorage.instance;
  final shell = StorageShell(storage, storage.ref('/'));
  stdout.write(shell);

  while (true) {
    final command = shell.prompt();
    final out = await command.execute();
    stdout.write(out);
  }
}
