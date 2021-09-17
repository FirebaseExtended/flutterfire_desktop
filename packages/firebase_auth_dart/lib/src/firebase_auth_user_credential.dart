import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'firebase_auth_user.dart';
import 'interop/dart_user_credential.dart';

/// Dart delegate implementation of [UserCredentialPlatform].
class UserCredential extends UserCredentialPlatform {
  // ignore: public_member_api_docs
  UserCredential(
    FirebaseAuthPlatform auth,
    DartUserCredential ipUserCredential,
  ) : super(
          auth: auth,
          additionalUserInfo: ipUserCredential.additionalUserInfo,
          credential: ipUserCredential.authCredential,
          user: User(auth, ipUserCredential.user),
        );
}
