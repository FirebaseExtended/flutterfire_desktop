import 'dart:async';
import 'dart:io';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:path/path.dart' as path;

import 'package:firebase_storage_dart/firebase_storage_dart.dart';

class StorageShell {
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  Reference ref;

  StorageShell(this.auth, this.storage, this.ref);

  Future<String> ls() async {
    final result = await ref.listAll();
    final b = StringBuffer();

    b.writeln(result.prefixes.map((e) => '${e.name}/').join('\n'));
    b.write(result.items.map((e) => e.name).join('\n'));

    return b.toString();
  }

  Future<String> download(String remotePath, String localPath) async {
    final filePath = path.join(Directory.current.path, localPath);
    final file = File(filePath);

    await ref.writeToFile(file).snapshotEvents.forEach((e) {
      final progress = e.bytesTransferred / e.totalBytes * 100;
      stdout.writeln('\r${progress.toStringAsFixed(2)}%');
    });

    return 'Downloaded to ${path.basename(filePath)}';
  }

  Future<String> upload(String localPath, String remotePath) async {
    final filePath = path.join(Directory.current.path, localPath);
    final file = File(filePath);

    stdout.writeln('Uploading ${path.basename(filePath)}...');

    await ref.putFile(file).snapshotEvents.forEach((e) {
      final progress = e.bytesTransferred / e.totalBytes * 100;
      stdout.write('\r${progress.toStringAsFixed(2)}%');
    });

    final downloadUrl = ref.getDownloadURL();

    return 'Available at $downloadUrl';
  }

  Future<void> cd(String path) async {
    final c = Completer();

    final newRef =
        path == '..' ? ref.parent ?? storage.ref('/') : ref.child(path);

    try {
      if (newRef != storage.ref('/')) {
        await newRef.list(ListOptions(maxResults: 1));
      }
      ref = newRef;
      c.complete();
    } on FirebaseException {
      rethrow;
    } on Exception catch (e) {
      c.completeError(e);
    }

    await c.future;
  }

  String pwd() {
    return ref.fullPath;
  }

  Future<String> login() async {
    await auth.signInAnonymously();
    return 'Logged in anonymously';
  }

  @override
  String toString() {
    return '${ref.name.isEmpty ? storage.bucket : ref.name} > ';
  }

  Command prompt() {
    String? input;

    while (input == null) {
      input = stdin.readLineSync();
    }

    return Command(this, input);
  }
}

class Command {
  final StorageShell shell;
  final String input;

  Command(this.shell, this.input);

  Future<String> execute() async {
    if (input.isEmpty) return '$shell';

    final chunks = input.split(' ').where((element) => element.isNotEmpty);
    final command = chunks.first;
    final args = chunks.skip(1).toList();

    String out;

    try {
      switch (command) {
        case 'ls':
          out = await shell.ls();
          break;
        case 'cd':
          if (args.isEmpty) {
            await shell.cd('/');
          } else {
            await shell.cd(args.first);
          }

          out = '';
          break;
        case 'login':
          out = await shell.login();
          break;
        case 'pwd':
          out = shell.pwd();
          break;
        case 'download':
          out = await shell.download(args[1], args[2]);
          break;
        case 'upload':
          out = await shell.upload(args[1], args[2]);
          break;
        default:
          out = 'Unknown command "$command"';
      }
    } on FirebaseException catch (e) {
      return '[${e.plugin}/${e.code}]: ${e.message}\n$shell';
    } catch (err) {
      out = err.toString();
    }

    return '${out.isEmpty ? '' : '$out\n'}$shell';
  }
}
