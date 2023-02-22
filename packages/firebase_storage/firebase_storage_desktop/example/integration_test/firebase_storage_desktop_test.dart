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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

    storage = FirebaseStorage.instance;
    await storage.useStorageEmulator('localhost', 9199);

    client = http.Client();
  });

  setUp(() async {
    await clearStorage();
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
}
