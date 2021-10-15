// ignore_for_file: require_trailing_commas

import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:firebase_auth_dart/firebase_auth.dart';
import 'package:googleapis/identitytoolkit/v3.dart';
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
  late FirebaseAuth realAuth;
  late FirebaseAuth fakeAuth;
  final user = MockUser();
  final userCred = MockUserCredential();

  final authWithSuccessRes = FirebaseAuth(
    options: APIOptions(
      apiKey: 'test',
      projectId: '',
      client: MockClient(_mockSuccessRequests),
    ),
  );
  final authWithFailedRes = FirebaseAuth(
    options: APIOptions(
      apiKey: 'test',
      projectId: '',
      client: MockClient(_mockFailedRequests),
    ),
  );

  late StreamQueue<User?> onAuthStateChanged;
  late StreamQueue<User?> onIdTokenChanged;

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

  setUpAll(() async {
    realAuth = FirebaseAuth(
      options: APIOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        projectId: 'react-native-firebase-testing',
      ),
    );

    await realAuth.useAuthEmulator();
    await emulatorClearAllUsers();

    onAuthStateChanged = StreamQueue(realAuth.onAuthStateChanged);
    onIdTokenChanged = StreamQueue(realAuth.onIdTokenChanged);
  });
  setUp(() {
    fakeAuth = MockAuth();

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
    // TODO(pr-Mais): once done create mock clients
    HttpOverrides.global = null;
  });

  group('Email and password ', () {
    test('sign-in updates currentUser and events.', () async {
      final credential = await realAuth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      expect(credential, isA<UserCredential>());
      expect(credential.user!.email, equals(mockEmail));
      expect(await onAuthStateChanged.next, isA<User>());
      expect(await onIdTokenChanged.next, isA<User>());

      await realAuth.signOut();
    });

    test('should throw.', () async {
      await emulatorClearAllUsers();
      expect(
        () => realAuth.signInWithEmailAndPassword(mockEmail, mockPassword),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'error code', ErrorCode.emailNotFound)),
      );
    });
    test('sign-out.', () async {
      await realAuth.createUserWithEmailAndPassword(mockEmail, mockPassword);

      await realAuth.signOut();

      expect(realAuth.currentUser, isNull);
      expect(await onAuthStateChanged.next, isNull);
      expect(await onIdTokenChanged.next, isNull);
    });
  });

  group('Anonymous ', () {
    test('sign-up.', () async {
      await realAuth.signInAnonymously();

      expect(realAuth.currentUser!.isAnonymous, true);
      expect(realAuth.currentUser!.email, isNull);
      expect((await realAuth.currentUser!.getIdTokenResult()).signInProvider,
          'anonymous');

      expect(await onAuthStateChanged.next, isA<User>());
      expect(await onIdTokenChanged.next, isA<User>());
    });
    test(
      'sign-up return current user if already sign-in anonymously.',
      () async {
        final credential = await realAuth.signInAnonymously();

        expect(credential.user!.isAnonymous, true);
        expect(credential.credential!.providerId, 'anonymous');

        expect(credential.user, equals(realAuth.currentUser));
      },
    );
    test('sign-out.', () async {
      await realAuth.signInAnonymously();
      await realAuth.signOut();

      expect(realAuth.currentUser, isNull);
      expect(await onAuthStateChanged.next, isNull);
      expect(await onIdTokenChanged.next, isNull);
    });
  });

  group('Fetch providers list ', () {
    test('for email with pssaword provider.', () async {
      final providersList =
          await authWithSuccessRes.fetchSignInMethodsForEmail(mockEmail);

      expect(providersList, ['password']);
    });

    test('for empty email throws.', () {
      expect(
        () => authWithFailedRes.fetchSignInMethodsForEmail(''),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('Use emulator ', () {
    test('returns project config.', () async {
      expect(
        await realAuth.useAuthEmulator(),
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
      final cred = await realAuth.createUserWithEmailAndPassword(
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
    test('delete()', () async {
      final cred = await realAuth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      await cred.user!.delete();

      expect(realAuth.currentUser, isNull);
      expect(
        cred.user!.delete(),
        throwsA(
          isA<AuthException>()
              .having((p0) => p0.code, 'error code', ErrorCode.userNotFound),
        ),
      );
      expect(
        realAuth.signInWithEmailAndPassword(
          mockEmail,
          mockPassword,
        ),
        throwsA(
          isA<AuthException>()
              .having((p0) => p0.code, 'error code', ErrorCode.emailNotFound),
        ),
      );
    });
    test('updateEmail()', () async {
      final cred = await realAuth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      final oldToken = realAuth.currentUser!.uid;

      await cred.user!.updateEmail('test+1@test.com');

      expect(realAuth.currentUser!.email, equals('test+1@test.com'));

      // Access token is updated
      expect(await realAuth.currentUser!.getIdToken(), isNot(equals(oldToken)));

      expect(
        realAuth.signInWithEmailAndPassword(
          mockEmail,
          mockPassword,
        ),
        throwsA(
          isA<AuthException>()
              .having((p0) => p0.code, 'error code', ErrorCode.emailNotFound),
        ),
      );
    });
    test('updateDisplayName() & updatePhotoURL()', () async {
      await realAuth.createUserWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      final oldToken = realAuth.currentUser!.uid;

      await realAuth.currentUser!.updateDisplayName(displayName);
      await realAuth.currentUser!.updatePhotoURL(photoURL);

      expect(realAuth.currentUser!.displayName, equals(displayName));
      expect(realAuth.currentUser!.photoURL, equals(photoURL));

      // Access token is updated
      expect(await realAuth.currentUser!.getIdToken(), isNot(equals(oldToken)));
    });
    test('sendEmailVerification()', () async {
      when(fakeAuth.currentUser).thenReturn(user);
      when(user.sendEmailVerification()).thenAnswer((_) async {});

      await fakeAuth.signInAnonymously();
      await fakeAuth.currentUser!.sendEmailVerification();

      verify(user.sendEmailVerification());
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
}
