import 'dart:typed_data';

import 'package:firebase_app_installations_dart/src/helpers/generate_fid.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'mock_data.dart';

void generateFidTests() {
  group(
    'generateFid()',
    (() {
      test('deterministically generates FIDs from known random byte list', () {
        for (var i = 0; i < 12; i++) {
          expect(
            generateFid(Uint8List.fromList(mockRandomValues[i])),
            equals(expectedFids[i]),
          );
        }
      });
      test('generate valid FIDs', () {
        for (var i = 0; i < 1000; i++) {
          final fid = generateFid();
          expect(fidPattern.hasMatch(fid), isTrue);
        }
      });
    }),
  );
}
