import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void setupTests() {
  late FirebaseAuth auth;

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

  tearDown(() async {
    if (useEmulator) {
      await emulatorClearAllUsers();
    }
  });

  group('IdToken ', () {
    test('should return a token.', () async {
      // Setup
      User? user;

      // Create a new mock user account.
      final userCredential = await auth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      user = userCredential.user;

      // Test
      String token = await user!.getIdToken();

      // Assertions
      expect(token.length, greaterThan(24));
    });

    test('setting forceRefresh to true generates a new token.', () async {
      // Setup
      User? user;

      // Create a new mock user account.
      final userCredential = await auth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      user = userCredential.user;

      // Get the current user token.
      String oldToken = await user!.getIdToken();

      // 1 second delay before sending another request.
      await Future.delayed(const Duration(seconds: 1));

      // Force refresh the token.
      String newToken = await auth.currentUser!.getIdToken(true);

      expect(newToken, isNot(equals(oldToken)));
    });

    test('should catch error.', () async {
      // Setup
      User? user;

      final userCredential = await auth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      user = userCredential.user!;

      // Needed for method to throw an error.
      await auth.signOut();

      await expectLater(
        user.getIdToken(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (p0) => p0.code,
            'FirebaseAuthException with code: not-signed-in',
            'not-signed-in',
          ),
        ),
      );
    });

    test('should return a valid IdTokenResult Object', () async {
      // Setup
      User? user;

      final userCredential = await auth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      user = userCredential.user!;

      // Test
      final idTokenResult = await user.getIdTokenResult();

      // Assertions
      expect(idTokenResult.token.runtimeType, equals(String));
      expect(idTokenResult.authTime.runtimeType, equals(DateTime));
      expect(idTokenResult.issuedAtTime.runtimeType, equals(DateTime));
      expect(idTokenResult.expirationTime.runtimeType, equals(DateTime));
      expect(idTokenResult.token.length, greaterThan(24));
      expect(idTokenResult.signInProvider, equals('password'));
    });
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
}
