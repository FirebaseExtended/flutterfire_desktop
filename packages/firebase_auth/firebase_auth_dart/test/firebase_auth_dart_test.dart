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

@GenerateMocks([User, Auth, UserCredential])
void main() {
  late Auth realAuth;
  late Auth fakeAuth;
  final user = MockUser();
  final userCred = MockUserCredential();

  final authWithSuccessRes = Auth(
    options: APIOptions(
      apiKey: 'test',
      projectId: '',
      client: MockClient(_mockSuccessRequests),
    ),
  );
  final authWithFailedRes = Auth(
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
    await http.delete(
      Uri.parse(
          'http://localhost:9099/emulator/v1/projects/react-native-firebase-testing/accounts'),
      headers: {
        'Authorization': 'Bearer owner',
      },
    );
  }

  setUpAll(() async {
    realAuth = Auth(
      options: APIOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        projectId: 'react-native-firebase-testing',
      ),
    );

    await realAuth.useEmulator();
    await emulatorClearAllUsers();
  });

  setUp(() async {
    onAuthStateChanged = StreamQueue(authWithSuccessRes.onAuthStateChanged);
    onIdTokenChanged = StreamQueue(authWithSuccessRes.onIdTokenChanged);
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
      final credential = await authWithSuccessRes.signInWithEmailAndPassword(
        mockEmail,
        mockPassword,
      );

      expect(credential, isA<UserCredential>());
      expect(credential.user!.email, equals(mockEmail));
      expect(await onAuthStateChanged.next, isA<User>());
      expect(await onIdTokenChanged.next, isA<User>());
    });
    test('sign-out updates currentUser and events.', () async {
      await authWithSuccessRes.signOut();

      expect(authWithSuccessRes.currentUser, isNull);
      expect(await onAuthStateChanged.next, isNull);
      expect(await onIdTokenChanged.next, isNull);
    });
    test('should throw.', () {
      expect(
        () => authWithFailedRes.signInWithEmailAndPassword(
            mockEmail, mockPassword),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'error code', ErrorCode.emailNotFound)),
      );
    });

    test('sign-up updates currentUser and events.', () async {
      final credential = await authWithSuccessRes
          .createUserWithEmailAndPassword(mockEmail, mockPassword);

      expect(credential, isA<UserCredential>());
      expect(credential.user!.email, equals(mockEmail));
      expect(await onAuthStateChanged.next, isA<User>());
      expect(await onIdTokenChanged.next, isA<User>());
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

  group('Password reset ', () {
    test('verify.', () async {
      await realAuth.sendPasswordResetEmail('mais@invertase.io');

      //expect(providersList, ['password']);
    });

    test('confirm.', () {});
  });

  group('Use emulator ', () {
    test('throw.', () {
      expect(realAuth.useEmulator(), throwsA(isA<AuthException>()));
    });

    test('update requester.', () async {
      expect(await realAuth.useEmulator(), isA<Map>());
    });
  });

  group('IdToken ', () {
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
}
