import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:firebase_storage_dart/firebase_storage_dart.dart';

class StorageShell {
  final FirebaseStorage storage;
  Reference ref;

  StorageShell(this.storage, this.ref);

  Future<String> ls() async {
    final result = await ref.listAll();
    final b = StringBuffer();

    b.write(result.prefixes.map((e) => '${e.name}/').join('\n'));
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
    final newRef = ref.child(path);

    try {
      await newRef.list(ListOptions(maxResults: 1));
      ref = newRef;
    } catch (e) {
      c.completeError('No such directory: $path');
    }

    await c.future;
  }

  String pwd() {
    return ref.fullPath;
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
    } catch (err) {
      out = err.toString();
    }

    return '${out.isEmpty ? '' : '$command: $out\n'}$shell';
  }
}
