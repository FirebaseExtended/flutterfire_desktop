// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_desktop_example/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' hide context;
import 'package:yaru/yaru.dart';

import 'app_theme.dart';

late FirebaseStorage storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: defaultTargetPlatform == TargetPlatform.macOS
        ? DefaultFirebaseOptions.macos
        : DefaultFirebaseOptions.web,
  );

  FirebaseStorage.instance.useStorageEmulator('localhost', 4040);
  storage = FirebaseStorage.instance;

  runApp(const StorageExampleApp());
}

class StorageExampleApp extends StatelessWidget {
  const StorageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage Example',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => YaruTheme(
          data: AppTheme.of(context),
          child: const Folder(initialPath: '/'),
        ),
      ),
    );
  }
}

class Folder extends StatefulWidget {
  final String initialPath;
  const Folder({super.key, required this.initialPath});

  @override
  State<Folder> createState() => _FolderState();
}

class _FolderState extends State<Folder> {
  late Reference ref = storage.ref(widget.initialPath);

  Future<ListResult> get listResult async {
    return ref.listAll();
  }

  Widget get appBarLeading {
    if (ref.parent == null) {
      return const Icon(Icons.storage);
    } else {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: pop,
      );
    }
  }

  void pop() {
    setState(() {
      ref = ref.parent ?? ref;
    });
  }

  void push(Reference ref) {
    setState(() {
      this.ref = ref;
    });
  }

  Future<void> createNewFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );

    if (name != null) {
      final metadata = SettableMetadata(customMetadata: {
        'purpose': 'A placeholder file to simulate a folder'
      });

      await ref.child(name).child('.keep').putString('', metadata: metadata);
      setState(() {});
    }
  }

  Future<void> upload(BuildContext context) async {
    final uploadType = await showDialog<UploadType>(
      context: context,
      builder: (context) => const UploadTypeDialog(),
    );

    if (uploadType == null) return;

    switch (uploadType) {
      case UploadType.string:
        uploadString(context);
        break;
      case UploadType.file:
        uploadFile(context);
        break;

      case UploadType.bytes:
        uploadBytes(context);
        break;
    }
  }

  Future<void> uploadString(BuildContext context) async {
    final navigator = Navigator.of(context);

    final ctrl = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload string'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'String content',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => navigator.pop(ctrl.text),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (content == null) return;

    await storage.ref('string.txt').putString(content);
    setState(() {});
  }

  Future<void> uploadFile(BuildContext context) async {
    final path = await promptPath(context);
    if (path == null) return;

    final name = basename(path);

    final metadata = SettableMetadata(
      contentType: lookupMimeType(path),
      customMetadata: {
        'uploaded_by': 'Flutter Desktop Example',
      },
    );

    await ref.child(name).putFile(File(path), metadata);
    setState(() {});
  }

  Future<void> uploadBytes(BuildContext context) async {
    final bytesList = List.generate(10 * 1024 * 1024, (index) => index % 256);
    final bytes = Uint8List.fromList(bytesList);
    final metadata = SettableMetadata(
      contentType: 'application/octet-stream',
      customMetadata: {
        'uploaded_by': 'Flutter Desktop Example',
      },
    );

    final task = ref.child('large.bin').putData(bytes, metadata);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uploading...'),
        content: TaskProgress(task: task),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final future = listResult;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading,
        title: Text(ref.fullPath),
        actions: [
          IconButton(
            onPressed: () => setState(() => ref = ref),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: createNewFolder,
            icon: const Icon(Icons.create_new_folder),
          ),
          IconButton(
            onPressed: () => upload(context),
            icon: const Icon(Icons.upload_file),
          ),
        ],
      ),
      body: FutureBuilder(
        key: ValueKey(future),
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final listResult = snapshot.data as ListResult;

          if (listResult.items.isEmpty && listResult.prefixes.isEmpty) {
            return Center(
              child: Text('${ref.bucket} is empty.'),
            );
          }

          return ListView(
            children: [
              ...listResult.prefixes.map(
                (prefix) => FolderTile(
                  open: push,
                  ref: prefix,
                  refreshCurrentFolder: () => setState(() {}),
                ),
              ),
              ...listResult.items.map(
                (item) => FileTile(
                  ref: item,
                  refreshCurrentFolder: () => setState(() {}),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum RefType {
  folder,
  file,
}

enum RefAction {
  open('Open', {RefType.folder, RefType.file}),
  copyPath('Copy path', {RefType.folder, RefType.file}, Icons.copy),
  getInfo('Get info', {RefType.file}, Icons.info),
  delete('Delete', {RefType.folder, RefType.file}, Icons.delete),
  download('Download', {RefType.file}, Icons.download);

  final String label;
  final IconData? icon;
  final Set<RefType> types;
  const RefAction(this.label, this.types, [this.icon]);
}

class RefActions extends StatelessWidget {
  final Reference ref;
  final RefType type;
  final VoidCallback refreshCurrentFolder;

  final void Function(Reference ref) open;

  const RefActions({
    super.key,
    required this.ref,
    required this.type,
    required this.open,
    required this.refreshCurrentFolder,
  });

  Future<void> handleAction(BuildContext context, RefAction action) async {
    switch (action) {
      case RefAction.open:
        open(ref);
        break;
      case RefAction.copyPath:
        Clipboard.setData(ClipboardData(text: ref.fullPath));
        const snackbar = SnackBar(content: Text('Copied path to clipboard'));
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
        break;
      case RefAction.getInfo:
        showDialog(
          context: context,
          builder: (context) => InfoDialog(ref: ref),
        );
        break;
      case RefAction.delete:
        await ref.delete();
        refreshCurrentFolder();
        break;
      case RefAction.download:
        final path = await promptPath(context);
        if (path == null) return;

        await showDownloadDialog(context: context, ref: ref, path: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RefAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        handleAction(context, value);
      },
      itemBuilder: (context) {
        return [
          for (var action in RefAction.values)
            if (action.types.contains(type))
              PopupMenuItem(
                value: action,
                child: Row(
                  children: [
                    if (action.icon != null)
                      Icon(
                        action.icon,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    const SizedBox(width: 8),
                    Text(action.label),
                  ],
                ),
              ),
        ];
      },
    );
  }
}

class FolderTile extends StatelessWidget {
  final Reference ref;
  final void Function(Reference ref) open;
  final VoidCallback refreshCurrentFolder;

  const FolderTile({
    super.key,
    required this.open,
    required this.ref,
    required this.refreshCurrentFolder,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(ref.name),
      onTap: () {
        open(ref);
      },
      trailing: RefActions(
        ref: ref,
        open: open,
        type: RefType.folder,
        refreshCurrentFolder: refreshCurrentFolder,
      ),
    );
  }
}

class FileTile extends StatefulWidget {
  final Reference ref;
  final VoidCallback refreshCurrentFolder;

  const FileTile({
    super.key,
    required this.ref,
    required this.refreshCurrentFolder,
  });

  @override
  State<FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
  Future<void> open(Reference ref) async {
    final meta = await ref.getMetadata();
    final contentType = meta.contentType;

    if (contentType != null && contentType.startsWith('image/')) {
      final imageScreen = ImageScreen(ref: ref);
      final route = MaterialPageRoute(builder: (context) => imageScreen);

      Navigator.of(context).push(route);
    } else if (contentType == 'text/plain') {
      final dialog = AlertDialog(
        title: Text(ref.name),
        content: FutureBuilder(
          future: ref.getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return FutureBuilder(
              future: ref.getData().then((value) => utf8.decode(value!)),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Text(snapshot.requireData);
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );

      showDialog(context: context, builder: (context) => dialog);
    } else {
      final snackBarText = Text('Cannot open file ${ref.fullPath}');
      final snackBar = SnackBar(content: snackBarText);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(widget.ref.name),
      onTap: () => open(widget.ref),
      trailing: RefActions(
        ref: widget.ref,
        open: open,
        type: RefType.file,
        refreshCurrentFolder: widget.refreshCurrentFolder,
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create a new folder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  autofocus: true,
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Folder name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(ctrl.text);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoDialog extends StatefulWidget {
  final Reference ref;
  const InfoDialog({super.key, required this.ref});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  late final metaFuture = widget.ref.getMetadata();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: metaFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return IntrinsicWidth(
              child: MetadataTable(metadata: snapshot.requireData),
            );
          },
        ),
      ),
    );
  }
}

class MetadataTable extends StatelessWidget {
  final FullMetadata metadata;
  const MetadataTable({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(150),
          1: IntrinsicColumnWidth(),
        },
        children: [
          if (metadata.bucket != null)
            TableRow(children: [const Text('Bucket'), Text(metadata.bucket!)]),
          TableRow(children: [const Text('Name'), Text(metadata.name)]),
          TableRow(children: [const Text('Path'), Text(metadata.fullPath)]),
          TableRow(children: [
            const Text('Size'),
            Text('${metadata.size} bytes'),
          ]),
          TableRow(children: [
            const Text('Created'),
            Text(metadata.timeCreated.toString()),
          ]),
          TableRow(children: [
            const Text('Updated'),
            Text(metadata.updated.toString()),
          ]),
          TableRow(children: [
            const Text('Custom metadata'),
            Text(
              const JsonEncoder.withIndent('    ')
                  .convert(metadata.customMetadata),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            )
          ]),
          TableRow(children: [
            const Text('Cache control'),
            Text(metadata.cacheControl ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Content disposition'),
            Text(metadata.contentDisposition ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Content encoding'),
            Text(metadata.contentEncoding ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Content language'),
            Text(metadata.contentLanguage ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Content type'),
            Text(metadata.contentType ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Generation'),
            Text(metadata.generation ?? 'null'),
          ]),
          TableRow(children: [
            const Text('Metadata generation'),
            Text(metadata.metadataGeneration ?? 'null'),
          ]),
          TableRow(children: [
            const Text('MD5 hash'),
            Text(metadata.md5Hash ?? 'null'),
          ]),
        ],
      ),
    );
  }
}

enum UploadType { file, bytes, string }

class UploadTypeDialog extends StatefulWidget {
  const UploadTypeDialog({super.key});

  @override
  State<UploadTypeDialog> createState() => _UploadTypeDialogState();
}

class _UploadTypeDialogState extends State<UploadTypeDialog> {
  UploadType? _type;

  void onChanged(UploadType? value) {
    setState(() {
      _type = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload type'),
      content: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What type of data would you like to upload?'),
            const SizedBox(height: 16),
            RadioListTile<UploadType>(
              title: const Text('Pick a file'),
              value: UploadType.file,
              groupValue: _type,
              onChanged: onChanged,
            ),
            RadioListTile<UploadType>(
              title: const Text('Generate bytes'),
              value: UploadType.bytes,
              groupValue: _type,
              onChanged: onChanged,
            ),
            RadioListTile<UploadType>(
              title: const Text('Enter a string'),
              value: UploadType.string,
              groupValue: _type,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              _type == null ? null : () => Navigator.of(context).pop(_type),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class ImageScreen extends StatefulWidget {
  final Reference ref;
  const ImageScreen({super.key, required this.ref});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  late final Future<String> downloadUrlFuture = widget.ref.getDownloadURL();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: downloadUrlFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.network(snapshot.requireData),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<String?> promptPath(BuildContext context) async {
  final ctrl = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('File location'),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'File path',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(ctrl.text);
          },
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}

Future<void> showDownloadDialog({
  required BuildContext context,
  required Reference ref,
  required String path,
}) async {
  final task = ref.writeToFile(File(join(path, ref.name)));

  final dialog = AlertDialog(
    title: Text('Downloading ${ref.name}'),
    content: TaskProgress(task: task),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );

  await showDialog(
    context: context,
    builder: (context) => dialog,
  );
}

class TaskProgress extends StatelessWidget {
  final Task task;
  const TaskProgress({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: task.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final event = snapshot.requireData;
        final progress = event.bytesTransferred / event.totalBytes;

        return Row(
          children: [
            if (task.snapshot.state == TaskState.running ||
                task.snapshot.state == TaskState.paused) ...[
              IconButton(
                onPressed: () {
                  if (task.snapshot.state == TaskState.running) {
                    task.pause();
                  } else {
                    task.resume();
                  }
                },
                icon: Icon(
                  task.snapshot.state == TaskState.running
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
              IconButton(
                onPressed: () {
                  task.cancel();
                },
                icon: const Icon(Icons.stop),
              ),
              const SizedBox(width: 16)
            ],
            Expanded(
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(width: 16),
            Text('${(progress * 100).toStringAsFixed(2)}%'),
          ],
        );
      },
    );
  }
}
