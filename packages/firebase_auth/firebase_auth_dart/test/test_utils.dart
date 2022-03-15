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
