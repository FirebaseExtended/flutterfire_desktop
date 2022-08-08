import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// Dart delegate implementation of [MultiFactorPlatform].
class MultiFactorDesktop extends MultiFactorPlatform {
  // ignore: public_member_api_docs
  MultiFactorDesktop(FirebaseAuthPlatform auth) : super(auth);
}
