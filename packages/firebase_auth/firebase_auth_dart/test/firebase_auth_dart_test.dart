import 'dart:convert';

import 'package:firebase_auth_dart/firebase_auth.dart';
import 'package:googleapis/identitytoolkit/v3.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:async/async.dart';

const mockEmail = 'test@test.com';
const mockPassword = 'password';

Response errorResponse(String code) {
  return Response(
    json.encode({
      'error': {'code': 404, 'message': code}
    }),
    404,
    headers: {'content-type': 'application/json'},
  );
}

Response successResponse(String body) {
  return Response(body, 200, headers: {'content-type': 'application/json'});
}

Future<Response> _mockSuccessRequests(Request req) async {
  String body;

  if (req.url.path.contains('verifyPassword')) {
    body = json
        .encode(VerifyPasswordResponse(email: mockEmail, idToken: '').toJson());
  } else if (req.url.path.contains('signupNewUser')) {
    body = json
        .encode(SignupNewUserResponse(email: mockEmail, idToken: '').toJson());
  } else if (req.url.path.contains('createAuthUri')) {
    body = json.encode(CreateAuthUriResponse(
        providerId: 'password', allProviders: ['password']).toJson());
  } else {
    return Response('Error: Unknown endpoint', 404);
  }

  return successResponse(body);
}

Future<Response> _mockFailedRequests(Request req) async {
  if (req.url.path.contains('verifyPassword')) {
    return errorResponse(ErrorCode.emailNotFound);
  } else if (req.url.path.contains('createAuthUri')) {
    return errorResponse(ErrorCode.invalidIdentifier);
  } else {
    return Response('Error: Unknown endpoint', 404);
  }
}

void main() {
  final authWithSuccessRes = Auth(
    options: AuthOptions(apiKey: 'test', projectId: ''),
    client: MockClient(_mockSuccessRequests),
  );
  final authWithFailedRes = Auth(
    options: AuthOptions(apiKey: 'test', projectId: ''),
    client: MockClient(_mockFailedRequests),
  );

  late StreamQueue<User?> onAuthStateChanged;
  late StreamQueue<User?> onIdTokenChanged;

  setUp(() {
    onAuthStateChanged = StreamQueue(authWithSuccessRes.onAuthStateChanged);
    onIdTokenChanged = StreamQueue(authWithSuccessRes.onIdTokenChanged);
  });

  group('Email and password ', () {
    test('sign-in updates currentUser and events.', () async {
      final credential = await authWithSuccessRes.signInWithEmailAndPassword(
          mockEmail, mockPassword);

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
}
