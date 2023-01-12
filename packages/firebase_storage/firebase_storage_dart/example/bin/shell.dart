import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/firebase_storage_dart.dart';
import 'package:firebase_storage_dart_example/firebase_options.dart';

void main(List<String> arguments) async {
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

  await FirebaseStorage.instance.ref('flutter-tests').list().then((value) {
    print(value.prefixes.map((e) => e.name));
    print(value.items.map((e) => e.name));
    return Future.wait(value.items.map((e) => e.getMetadata()));
  }).then((value) {
    print(value);
  });

  // final storage = FirebaseStorage.instance;
  // final shell = StorageShell(storage, storage.ref('/'));
  // stdout.write(shell);

  // while (true) {
  //   final command = shell.prompt();
  //   final out = await command.execute();
  //   stdout.write(out);
  // }
}
