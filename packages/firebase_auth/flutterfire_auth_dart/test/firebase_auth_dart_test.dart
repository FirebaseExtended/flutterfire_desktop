// ignore_for_file: require_trailing_commas

import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutterfire_auth_dart/flutterfire_auth_dart.dart';
import 'package:flutterfire_core_dart/flutterfire_core_dart.dart';
import 'package:googleapis/identitytoolkit/v3.dart' hide UserInfo;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'firebase_auth_dart_test.mocks.dart';

const mockEmail = 'test@test.com';
const mockPassword = 'password';
const photoURL =
    'https://images.pexels.com/photos/320014/pexels-photo-320014.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260';
const displayName = 'Invertase';

http.Response errorResponse(String code) {
  return http.Response(
    json.encode({
      'error': {'code': 404, 'message': code}
    }),
    404,
    headers: {'content-type': 'application/json'},
  );
}

http.Response successResponse(String body) {
  return http.Response(body, 200,
      headers: {'content-type': 'application/json'});
}

Future<http.Response> _mockSuccessRequests(http.Request req) async {
  String body;

  if (req.url.path.contains('verifyPassword')) {
    body = json
        .encode(VerifyPasswordResponse(email: mockEmail, idToken: '').toJson());
  } else if (req.url.path.contains('signupNewUser')) {
    body = json
        .encode(SignupNewUserResponse(email: mockEmail, idToken: '').toJson());
  } else if (req.url.path.contains('createAuthUri')) {
    body = json.encode(
      CreateAuthUriResponse(providerId: 'password', allProviders: ['password'])
          .toJson(),
    );
  } else {
    return http.Response('Error: Unknown endpoint', 404);
  }

  return successResponse(body);
}

Future<http.Response> _mockFailedRequests(http.Request req) async {
  if (req.url.path.contains('verifyPassword')) {
    return errorResponse(ErrorCode.emailNotFound);
  } else if (req.url.path.contains('createAuthUri')) {
    return errorResponse(ErrorCode.invalidIdentifier);
  } else {
    return http.Response('Error: Unknown endpoint', 404);
  }
}

@GenerateMocks([User, FirebaseAuth, UserCredential])
void main() {
  late FirebaseAuth auth;
  late FirebaseAuth fakeAuth;
  final user = MockUser();
  final userCred = MockUserCredential();

  /// Deletes all users from the Auth emulator.
  Future<void> emulatorClearAllUsers() async {
    //await realAuth.signOut();
    await http.delete(
      Uri.parse(
          'http://localhost:9099/emulator/v1/projects/react-native-firebase-testing/accounts'),
      headers: {
        'Authorization': 'Bearer owner',
      },
    );
  }

  late StreamQueue<User?> onAuthStateChanged;
  late StreamQueue<User?> onIdTokenChanged;
  group('$FirebaseAuth', () {
    setUpAll(() async {
      const options = FirebaseOptions(
        appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        projectId: 'react-native-firebase-testing',
        messagingSenderId: '448618578101',
      );

      await Firebase.initializeApp(options: options);

      auth = FirebaseAuth.instance;

      await auth.useAuthEmulator();

      onAuthStateChanged = StreamQueue(auth.onAuthStateChanged);
      onIdTokenChanged = StreamQueue(auth.onIdTokenChanged);
    });

    setUp(() async {
      await emulatorClearAllUsers();

      fakeAuth = MockFirebaseAuth();

      when(fakeAuth.onAuthStateChanged)
          .thenAnswer((_) => Stream.fromIterable([user]));
      when(fakeAuth.onIdTokenChanged)
          .thenAnswer((_) => Stream.fromIterable([user]));
      when(fakeAuth.signInAnonymously())
          .thenAnswer((_) => Future<UserCredential>.value(userCred));
      when(userCred.user).thenReturn(user);
      when(fakeAuth.currentUser).thenReturn(user);
    });

    setUpAll(() {
      // Avoid HTTP error 400 mocked returns
      // TODO(pr-mais): once done create mock clients
      HttpOverrides.global = null;
    });

    group('Email and password ', () {
      test('sign-in updates currentUser and events.', () async {
        final credential = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        expect(credential, isA<UserCredential>());
        expect(credential.user!.email, equals(mockEmail));
        expect(await onAuthStateChanged.next, isA<User>());
        expect(await onIdTokenChanged.next, isA<User>());

        await auth.signOut();
      });

      test('should throw.', () async {
        await emulatorClearAllUsers();
        expect(
          () => auth.signInWithEmailAndPassword(mockEmail, mockPassword),
          throwsA(isA<FirebaseAuthException>()
              .having((e) => e.code, 'error code', ErrorCode.emailNotFound)),
        );
      });
      test('sign-out.', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        await auth.signOut();

        expect(auth.currentUser, isNull);
        expect(await onAuthStateChanged.next, isNull);
        expect(await onIdTokenChanged.next, isNull);
      });
    });

    group('Anonymous ', () {
      test('sign-up.', () async {
        await auth.signInAnonymously();

        expect(auth.currentUser!.isAnonymous, true);
        expect(auth.currentUser!.email, isNull);
        expect((await auth.currentUser!.getIdTokenResult()).signInProvider,
            'anonymous');

        expect(await onAuthStateChanged.next, isA<User>());
        expect(await onIdTokenChanged.next, isA<User>());
      });
      test(
        'sign-up return current user if already sign-in anonymously.',
        () async {
          final credential = await auth.signInAnonymously();

          expect(credential.user!.isAnonymous, true);
          expect(credential.credential!.providerId, 'anonymous');

          expect(credential.user, equals(auth.currentUser));
        },
      );
      test('sign-out.', () async {
        await auth.signInAnonymously();
        await auth.signOut();

        expect(auth.currentUser, isNull);
        expect(await onAuthStateChanged.next, isNull);
        expect(await onIdTokenChanged.next, isNull);
      });
    });

    group('Fetch providers list ', () {
      test('for email with pssaword provider.', () async {
        auth.setApiClient(MockClient(_mockSuccessRequests));

        final providersList = await auth.fetchSignInMethodsForEmail(mockEmail);

        expect(providersList, ['password']);
      });

      test('for empty email throws.', () {
        auth.setApiClient(MockClient(_mockFailedRequests));
        expect(
          () => auth.fetchSignInMethodsForEmail(''),
          throwsA(
            isA<FirebaseAuthException>().having((p0) => p0.code,
                'invalid identifier code', ErrorCode.invalidIdentifier),
          ),
        );
      });
    });

    group('Use emulator ', () {
      test('returns project config.', () async {
        expect(
          await auth.useAuthEmulator(),
          isA<Map>().having((p0) => p0.containsKey('signIn'),
              'returns project emulator config', true),
        );
      });
    });

    group('IdToken ', () {
      setUp(() async {
        await emulatorClearAllUsers();
      });
      test('getIdTokenResult()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );
        final token = await cred.user!.getIdTokenResult();
        expect(token, isA<IdTokenResult>());
      });
      test('user have IdToken and refreshToken.', () async {
        when(user.refreshToken).thenReturn('refreshToken');
        when(user.getIdToken()).thenAnswer((_) async => 'token');

        expect(await fakeAuth.currentUser!.getIdToken(), isA<String>());
        expect(fakeAuth.currentUser!.refreshToken, isA<String>());

        verify(user.getIdToken());
        verify(user.refreshToken);
      });
      test('force refresh.', () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');
        when(user.getIdToken(true)).thenAnswer((_) async => 'token_refreshed');

        final userCred = await fakeAuth.signInAnonymously();
        final oldToken = await userCred.user!.getIdToken();
        final token = await fakeAuth.currentUser!.getIdToken(true);

        expect(token, isNot(equals(oldToken)));
      });
      test("getIdToken doesn't force refresh.", () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');

        await fakeAuth.signInAnonymously();
        final token = await fakeAuth.currentUser!.getIdToken();

        expect(token, equals(await fakeAuth.currentUser!.getIdToken()));
      });
      test('event recieved once force refreshed.', () async {
        when(user.getIdToken()).thenAnswer((_) async => 'token');
        when(user.getIdToken(true)).thenAnswer((_) async => 'token_refreshed');

        final userCred = await fakeAuth.signInAnonymously();
        final oldToken = await userCred.user!.getIdToken();

        expect(
          await (await fakeAuth.onIdTokenChanged.last)!.getIdToken(true),
          isNot(equals(oldToken)),
        );
      });
    });

    group('User ', () {
      test('sendEmailVerification()', () async {
        when(fakeAuth.currentUser).thenReturn(user);
        when(user.sendEmailVerification()).thenAnswer((_) async {});

        await fakeAuth.signInAnonymously();
        await fakeAuth.currentUser!.sendEmailVerification();

        verify(user.sendEmailVerification());
      });
      test('updateEmail()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        await cred.user!.updateEmail('test+1@test.com');

        expect(auth.currentUser!.email, equals('test+1@test.com'));

        // Access token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));

        expect(
          auth.signInWithEmailAndPassword(
            mockEmail,
            mockPassword,
          ),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', ErrorCode.emailNotFound),
          ),
        );
      });
      test('updateDisplayName() & updatePhotoURL()', () async {
        await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        await auth.currentUser!.updateDisplayName(displayName);
        await auth.currentUser!.updatePhotoURL(photoURL);

        expect(auth.currentUser!.displayName, equals(displayName));
        expect(auth.currentUser!.photoURL, equals(photoURL));

        // Access token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));
      });
      test('updatePassword()', () async {
        await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final oldToken = auth.currentUser!.uid;

        // update the password
        await auth.currentUser!.updatePassword('newPassword');

        await auth.signInWithEmailAndPassword(mockEmail, 'newPassword');

        // Access token is updated
        expect(await auth.currentUser!.getIdToken(), isNot(equals(oldToken)));
      });
      test('delete()', () async {
        final cred = await auth.createUserWithEmailAndPassword(
          mockEmail,
          mockPassword,
        );

        final user = cred.user;

        await user?.delete();

        expect(auth.currentUser, isNull);
        expect(
          user?.delete(),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', ErrorCode.userNotFound),
          ),
        );
        expect(
          auth.signInWithEmailAndPassword(
            mockEmail,
            mockPassword,
          ),
          throwsA(
            isA<FirebaseAuthException>()
                .having((p0) => p0.code, 'error code', ErrorCode.emailNotFound),
          ),
        );
      });
      group('linkWithCredential()', () {
        setUp(() {
          when(user.linkWithCredential(any)).thenAnswer((_) async => userCred);
        });
        test('should call linkWithCredential()', () async {
          const newEmail = 'new@email.com';

          final credential =
              EmailAuthProvider.credential(email: newEmail, password: 'test')
                  as EmailAuthCredential;

          await fakeAuth.currentUser!.linkWithCredential(credential);

          verify(user.linkWithCredential(credential));
        });
      });
      group('reauthenticateWithCredential()', () {
        setUp(() {
          when(user.reauthenticateWithCredential(any))
              .thenAnswer((_) async => userCred);
        });
        test('should call reauthenticateWithCredential()', () async {
          const newEmail = 'new@email.com';

          final credential =
              EmailAuthProvider.credential(email: newEmail, password: 'test')
                  as EmailAuthCredential;

          await fakeAuth.currentUser!.reauthenticateWithCredential(credential);

          verify(user.reauthenticateWithCredential(credential));
        });
      });
      test('.metadata', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        final metadata = auth.currentUser!.metadata!;

        expect(metadata.creationTime!.isBefore(DateTime.now()), isTrue);
        expect(metadata.lastSignInTime!.isBefore(DateTime.now()), isTrue);
      });
      test('.providerData', () async {
        await auth.createUserWithEmailAndPassword(mockEmail, mockPassword);

        expect(
          auth.currentUser!.providerData.isNotEmpty,
          isTrue,
        );
      });
    });

    group('StorageBox ', () {
      test('put a new value.', () {
        final box = StorageBox.instanceOf('box');
        box.putValue('key', '123');

        expect(box.getValue('key'), '123');
      });
      test('put a null value does not add the value.', () {
        final box = StorageBox.instanceOf('box');
        box.putValue('key_2', null);
        expect(
          () => box.getValue('key_2'),
          throwsA(isA<StorageBoxException>()),
        );
      });
      test('get a key that does not exist.', () {
        final box = StorageBox.instanceOf('box');
        expect(
          () => box.getValue('random_key'),
          throwsA(isA<StorageBoxException>()),
        );
      });
      test('get a key from a box that does not exist.', () {
        final box = StorageBox.instanceOf('box_');
        expect(
          () => box.getValue('key'),
          throwsA(isA<StorageBoxException>()),
        );
      });
    });
  });
}
