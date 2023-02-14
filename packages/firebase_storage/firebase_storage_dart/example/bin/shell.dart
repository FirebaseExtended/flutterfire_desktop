import 'dart:async';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart_example/firebase_options.dart';

Future<void> main(List<String> arguments) async {
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseAuth.instance.useAuthEmulator();
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

  if (FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
  }

  await FirebaseAuth.instance.signInAnonymously();

  final storage = FirebaseStorage.instance;

  try {
    final ref = storage.ref('protected/large.mov');
    final newMeta = await ref.updateMetadata(SettableMetadata(
      customMetadata: {'test': 'test'},
    ));

    print(newMeta);
  } catch (err) {
    print(err);
  }

  // try {
  //   final snapshot = await storage
  //       .ref('writeOnly.txt')
  //       .putData(Uint8List.fromList(utf8.encode('hello world')));

  //   print(snapshot);
  // } catch (err) {
  //   print(err);
  // }

  // try {
  //   await storage.ref('forbidden.txt').putString('can I write this?');
  //   print('Should never be called');
  //   exit(-1);
  // } catch (err) {
  //   print(err);
  // }

  // final jsonMeta = SettableMetadata(contentType: 'application/json');

  // try {
  //   final snapshot = await storage
  //       .ref('flutter-tests/test-string.json')
  //       .putString('{"test": "test"}', metadata: jsonMeta);

  //   print(snapshot);
  // } catch (err) {
  //   print(err);
  // }

  // try {
  //   final snapshot = await storage
  //       .ref('flutter-tests/test-string.json')
  //       .putData(Uint8List.fromList(utf8.encode('{"test": "test"}')), jsonMeta);

  //   print(snapshot);
  // } catch (err) {
  //   print(err);
  // }

  // final shell = StorageShell(storage, storage.ref('/'));
  // stdout.write(shell);

  // while (true) {
  //   final command = shell.prompt();
  //   final out = await command.execute();
  //   stdout.write(out);
  // }
}
