import 'dart:convert';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:http/http.dart' as http;

const mockEmail = 'test@test.com';
const mockPassword = 'password';
const photoURL =
    'https://images.pexels.com/photos/320014/pexels-photo-320014.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260';
const displayName = 'Invertase';
const mockOobCode = 'code';

const _testFirebaseProjectId = 'react-native-firebase-testing';
const testEmulatorHost = 'localhost';
const testEmulatorPort = 9099;

const bool useEmulator = true;

/// Deletes all users from the Auth emulator.
Future<void> emulatorClearAllUsers() async {
  await http.delete(
    Uri.parse(
      'http://$testEmulatorHost:$testEmulatorPort/emulator/v1/projects/$_testFirebaseProjectId/accounts',
    ),
    headers: {
      'Authorization': 'Bearer owner',
    },
  );
}

/// Retrieve a sms phone authentication code that may have been sent for a specific
/// phone number.
Future<String?> emulatorPhoneVerificationCode(String phoneNumber) async {
  final response = await http.get(
    Uri.parse(
      'http://$testEmulatorHost:$testEmulatorPort/emulator/v1/projects/$_testFirebaseProjectId/verificationCodes',
    ),
    headers: {
      'Authorization': 'Bearer owner',
    },
  );
  final responseBody = Map<String, dynamic>.from(jsonDecode(response.body));
  final verificationCodes =
      List<Map<String, dynamic>>.from(responseBody['verificationCodes']);
  return verificationCodes.reversed.firstWhere(
    (verificationCode) => verificationCode['phoneNumber'] == phoneNumber,
    orElse: () => {'code': 'NOT_FOUND'},
  )['code'];
}

Future<void> ensureSignedOut() async {
  if (FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
  }
}

/// Create a custom authentication token with optional claims and tenant id.
/// Useful for testing signInWithCustomToken, custom claims and tenant id data.
// Reverse engineered from;
//  - https://github.com/firebase/firebase-admin-node/blob/d961c3f705a8259762a796ac4f4d6a6dd0992eb1/src/auth/token-generator.ts#L236-L254
//  - https://github.com/firebase/firebase-admin-node/blob/d961c3f705a8259762a796ac4f4d6a6dd0992eb1/src/auth/token-generator.ts#L309-L365
String emulatorCreateCustomToken(
  String uid, {
  Map<String, Object> claims = const {},
  String tenantId = '',
}) {
  final iat = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

  final jwtHeaderEncoded = base64
      .encode(
        utf8.encode(
          jsonEncode({
            'alg': 'none',
            'typ': 'JWT',
          }),
        ),
      )
      // Note that base64 padding ("=") must be omitted as per JWT spec.
      .replaceAll(RegExp(r'=+$'), '');

  final jwtBody = {
    'aud':
        'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    'iat': iat,
    'exp': iat + const Duration(hours: 1).inSeconds,
    'iss': 'firebase-auth-emulator@example.com',
    'sub': 'firebase-auth-emulator@example.com',
    'uid': uid,
  };
  if (claims.isNotEmpty) {
    jwtBody['claims'] = claims;
  }
  if (tenantId.isNotEmpty) {
    jwtBody['tenant_id'] = tenantId;
  }

  final jwtBodyEncoded = base64
      .encode(utf8.encode(jsonEncode(jwtBody)))
      // Note that base64 padding ("=") must be omitted as per JWT spec.
      .replaceAll(RegExp(r'=+$'), '');

  // Alg is set to none so signature should be empty.
  const jwtSignature = '';
  return '$jwtHeaderEncoded.$jwtBodyEncoded.$jwtSignature';
}
