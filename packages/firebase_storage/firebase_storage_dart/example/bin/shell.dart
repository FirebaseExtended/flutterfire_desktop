import 'dart:async';
import 'dart:io';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart_example/firebase_options.dart';
import 'package:firebase_storage_dart_example/firebase_storage_dart_example.dart';

Future<void> main(List<String> arguments) async {
  await Firebase.initializeApp(options: firebaseOptions);

  // start a proxy server from scripts/storage with npm start
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  final storage = FirebaseStorage.instance;
  final auth = FirebaseAuth.instance;

  final shell = StorageShell(auth, storage, storage.ref('/'));

  stdout.write(shell);

  while (true) {
    final command = shell.prompt();
    final out = await command.execute();
    stdout.write(out);
  }
}
