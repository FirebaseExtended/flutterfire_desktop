import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void setupTests() {
  late FirebaseAuth auth;

  group('IdToken ', () {
    setUpAll(() async {
      const options = FirebaseOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        authDomain: 'react-native-firebase-testing.firebaseapp.com',
        databaseURL: 'https://react-native-firebase-testing.firebaseio.com',
        projectId: 'react-native-firebase-testing',
        storageBucket: 'react-native-firebase-testing.appspot.com',
        messagingSenderId: '448618578101',
        appId: '1:448618578101:web:0b650370bb29e29cac3efc',
        measurementId: 'G-F79DJ0VFGS',
      );

      await Firebase.initializeApp(options: options);

      auth = FirebaseAuth.instance;

      if (useEmulator) {
        await auth.useAuthEmulator();
      }
    });

    setUp(() async {
      if (useEmulator) {
        await emulatorClearAllUsers();
      }
      await ensureSignedOut();
    });

    test('getIdTokenResult()', () async {
      final cred = await auth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );
      final token = await cred.user!.getIdTokenResult();
      expect(token, isA<IdTokenResult>());
    });

    group('signInWithCustomToken()', () {
      test('signs in with custom token', () async {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        final uid = userCredential.user!.uid;
        final claims = {
          'roles': [
            {'role': 'member'},
            {'role': 'admin'}
          ]
        };

        await ensureSignedOut();

        expect(FirebaseAuth.instance.currentUser, null);

        final token = emulatorCreateCustomToken(uid, claims: claims);

        final cred = await auth.signInWithCustomToken(token);

        expect(auth.currentUser, equals(cred.user));
        final user = cred.user!;
        expect(user.isAnonymous, isFalse);
        expect(user.uid, equals(uid));

        final idTokenResult =
            await FirebaseAuth.instance.currentUser!.getIdTokenResult();

        expect(idTokenResult.claims!['roles'], isA<List>());
        expect(idTokenResult.claims!['roles'][0], isA<Map>());
        expect(idTokenResult.claims!['roles'][0]['role'], 'member');
      });
    });
  });
}
