import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_desktop_example/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import 'package:path/path.dart';

late FirebaseStorage storage;
late http.Client client;

class Hashes {
  static String largeUpload = 'jlNGODityFmHO7saFy4asQ==';
  static String smallUpload = 'CY9rzUYh03PK3k6DJie09g==';
  static String largeDownload = 'FHXuQ7SczGXOcsdj5TpWyQ==';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

    storage = FirebaseStorage.instance;
    await storage.useStorageEmulator('localhost', 9199);

    client = http.Client();
  });

  final bytes = List.generate(10 * 1024 * 1024, (index) => index % 256);
  final largeBin = Uint8List.fromList(bytes);

  setUp(() async {
    await clearStorage();
    setServerSpeed(1024 * 1024 * 100);
  });

  tearDownAll(() async {
    await clearStorage();
  });

  group('Reference', () {
    group('getDownloadUrl()', () {
      test('returns correct download url', () async {
        await putString('test.txt', 'test');
        final url = await storage.ref('test.txt').getDownloadURL();
        final res = await client.get(Uri.parse(url));

        expect(res.body, 'test');
      });
    });

    group('delete()', () {
      test('deletes file', () async {
        await putString('test.txt', 'test');
        await storage.ref('test.txt').delete();

        expect(
          () => verifyExists('test.txt'),
          throwsA(fileNotExists('test.txt')),
        );
      });
    });

    group('getMetadata()', () {
      test('returns correct metadata', () async {
        await putString('test.txt', 'test');
        final metadata = await storage.ref('test.txt').getMetadata();

        expect(metadata.name, 'test.txt');
        expect(metadata.bucket, 'flutterfire-e2e-tests.appspot.com');
        expect(metadata.fullPath, 'test.txt');
        expect(metadata.size, 4);
        expect(metadata.updated, isNotNull);
        expect(metadata.md5Hash, "CY9rzUYh03PK3k6DJie09g==");
      });
    });

    group('list()', () {
      test('returns correct list of objects', () async {
        for (var i = 0; i < 50; i++) {
          await putString('test-$i.txt', 'test-$i');
        }

        final list = await storage.ref().list();
        final items = list.items.toList();
        expect(items.length, 50);
      });

      test('respects ListOptions', () async {
        for (var i = 0; i < 50; i++) {
          await putString('test-$i.txt', 'test-$i');
        }

        const options = ListOptions(maxResults: 10);

        final list = await storage.ref().list(options);
        final items = list.items.toList();
        expect(items.length, 10);
      });
    });

    group('listAll()', () {
      test('returns correct list of objects', () async {
        for (int i = 0; i < 11; i++) {
          final promises = <Future>[];

          for (int j = 0; j < 100; j++) {
            promises.add(putString('test-$i-$j.txt', 'test-$i-$j'));
          }

          await Future.wait(promises);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final list = await storage.ref().listAll();
        final items = list.items.toList();
        expect(items.length, 1100);
      });
    });

    group('getData()', () {
      test('returns contents of the file', () async {
        await putString('test.txt', 'test');
        final data = await storage.ref('test.txt').getData();
        final decoded = utf8.decode(data!);
        expect(decoded, 'test');
      });
    });

    group('putData()', () {
      test('uploads file', () async {
        final data = utf8.encode('test');
        await storage.ref('test.txt').putData(Uint8List.fromList(data));

        await verifyExists('test.txt');
        await verifyMD5Hash('test.txt', 'CY9rzUYh03PK3k6DJie09g==');
      });
    });

    group('putFile()', () {
      test('uploads file', () async {
        final path = join(
          Directory.current.path,
          'integration_test',
          'mock_files',
          'test-image.png',
        );

        final f = File(path);

        await storage.ref('test-image.png').putFile(f);

        await verifyExists('test-image.png');
        await verifyMD5Hash('test-image.png', 'egiahhIT8ps6OceoWQGQRw==');
      });
    });

    group('putString()', () {
      test('uploads string', () async {
        await storage.ref('test.txt').putString('test');

        await verifyExists('test.txt');
        await verifyMD5Hash('test.txt', 'CY9rzUYh03PK3k6DJie09g==');
      });

      test('respects PutStringFormat', () async {
        final base64 = base64Encode(utf8.encode('test'));
        await storage
            .ref('test.txt')
            .putString(base64, format: PutStringFormat.base64);

        await verifyExists('test.txt');
        await verifyMD5Hash('test.txt', 'CY9rzUYh03PK3k6DJie09g==');
      });
    });

    group('updateMetadata()', () {
      test('updates metadata', () async {
        await putString('test.txt', 'test');

        final newMeta = SettableMetadata(
          contentType: 'text/plain',
          customMetadata: {'foo': 'bar'},
        );

        final updated = await storage.ref('test.txt').updateMetadata(newMeta);

        expect(updated.contentType, 'text/plain');
        expect(updated.customMetadata, {'foo': 'bar'});
        expect(updated.metadataGeneration, '2');
      });
    });
  });

  group('UploadTask', () {
    test('uses single shot upload for small files', () async {
      final task = storage.ref('test.txt').putString('test');
      final events = await task.snapshotEvents.toList();
      expect(events.length, 1);
      await verifyExists('test.txt');
      await verifyMD5Hash('test.txt', Hashes.smallUpload);
    });

    test('uses resumable upload for large files', () async {
      final ref = storage.ref('large.bin');

      final task = ref.putData(Uint8List.fromList(largeBin));
      final events = await task.snapshotEvents.toList();

      expect(events.length, greaterThan(1));
      expect(events.last.bytesTransferred, largeBin.length);
      expect(events.last.state, TaskState.success);

      verifyExists('large.bin');
      verifyMD5Hash('large.bin', Hashes.largeUpload);
    });

    test('is cancellable', () async {
      final ref = storage.ref('large.bin');

      final task = ref.putData(largeBin);
      late FirebaseException error;

      task.snapshotEvents.listen((event) {}, onError: (e) {
        error = e;
      });
      final firstEvent = await task.snapshotEvents.first;

      expect(firstEvent.state, TaskState.running);
      expect(firstEvent.bytesTransferred, 262144);

      final cancelled = await task.cancel();
      expect(cancelled, true);

      expect(task.snapshot.state, TaskState.canceled);
      await expectLater(
        task,
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'canceled'),
        ),
      );

      expect(error, isNotNull);
      expect(error.code, 'canceled');

      verifyNotExists('large.bin');
    });

    test('could be paused and resumed', () async {
      final ref = storage.ref('large.bin');

      final task = ref.putData(largeBin);

      final firstEvent = await task.snapshotEvents.first;

      expect(firstEvent.state, TaskState.running);
      expect(firstEvent.bytesTransferred, 262144);

      final paused = await task.pause();

      expect(paused, true);

      await Future.delayed(const Duration(seconds: 2));
      verifyNotExists('large.bin');

      final resumed = await task.resume();

      expect(resumed, true);

      final lastEvent = await task.snapshotEvents.last;

      expect(lastEvent.state, TaskState.success);
      expect(lastEvent.bytesTransferred, largeBin.length);

      verifyExists('large.bin');
      verifyMD5Hash('large.bin', Hashes.largeUpload);
    });
  });

  group('DownloadTask', () {
    final file = File('integration_test/downloads/large.bin');

    setUp(() async {
      await uploadLargeFile('large.bin');
      setServerSpeed(1024 * 1024);
    });

    tearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('downloads a file', () async {
      final ref = storage.ref('large.bin');
      await ref.writeToFile(file);

      expect(file.existsSync(), true);
      expect(file.lengthSync(), 20 * 1024 * 1024);
      expect(await getMD5Hash(file.path), Hashes.largeDownload);
    });

    test('is cancellable', () async {
      final ref = storage.ref('large.bin');
      final task = ref.writeToFile(file);

      late FirebaseException error;

      task.snapshotEvents.listen((event) {}, onError: (e) {
        error = e;
      });

      final snapshots = await task.snapshotEvents.take(2).toList();
      final snapshot = snapshots.last;

      expect(snapshot.state, TaskState.running);
      expect(file.existsSync(), true);

      final cancelled = await task.cancel();

      expect(cancelled, true);
      expect(task.snapshot.state, TaskState.canceled);

      await expectLater(
        task,
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'canceled'),
        ),
      );

      expect(file.existsSync(), false);

      expect(error, isNotNull);
      expect(error.code, 'canceled');
    });

    test('could be paused and resumed', () async {
      final ref = storage.ref('large.bin');
      final task = ref.writeToFile(file);

      final snapshots = await task.snapshotEvents.take(2).toList();
      final snapshot = snapshots.last;

      expect(snapshot.state, TaskState.running);
      final paused = await task.pause();

      expect(file.existsSync(), true);

      await Future.delayed(const Duration(seconds: 1));
      expect(file.lengthSync(), snapshot.bytesTransferred);
      expect(paused, true);

      await Future.delayed(const Duration(seconds: 1));
      expect(file.lengthSync(), snapshot.bytesTransferred);

      final resumed = await task.resume();
      expect(resumed, true);

      final result = await task;

      expect(result.state, TaskState.success);

      expect(file.existsSync(), true);
      expect(file.lengthSync(), 20 * 1024 * 1024);
      expect(result.bytesTransferred, 20 * 1024 * 1024);
      expect(await getMD5Hash(file.path), Hashes.largeDownload);
    });
  });
}
