import '../firebase_auth_dart.dart';

/// Typedef for handling errors via phone number verification.
typedef PhoneVerificationFailed = void Function(FirebaseAuthException error);

/// Typedef for handling when Firebase sends a SMS code to the provided phone
/// number.
typedef PhoneCodeSent = void Function(
  String verificationId,
  int? forceResendingToken,
);

/// Typedef for handling automatic phone number timeout resolution.
typedef PhoneCodeAutoRetrievalTimeout = void Function(String verificationId);
