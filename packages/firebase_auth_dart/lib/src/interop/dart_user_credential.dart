import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'dart_user.dart';

class DartUserCredential {
  // ignore: public_member_api_docs
  DartUserCredential({
    required this.additionalUserInfo,
    required this.authCredential,
    required this.user,
  });

  final AuthCredential authCredential;
  final AdditionalUserInfo additionalUserInfo;
  final DartUser user;
}
