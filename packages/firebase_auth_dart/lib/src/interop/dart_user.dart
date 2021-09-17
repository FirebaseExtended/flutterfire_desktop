import 'package:googleapis/identitytoolkit/v3.dart';

/// User object wrapping the responses from identity toolkit.
class DartUser {
  /// Default constructor.
  DartUser(
    this.token,
    this.uid,
    this.email,
  );

  /// Return a dart user object  from `verifyPassword` endpoint in Google's identity toolkit.
  DartUser.fromVerifyPasswordResponse(VerifyPasswordResponse response)
      : token = response.idToken ?? '',
        email = response.email,
        uid = response.localId ?? '';

  /// Return a dart user object  from `signupNewUser` endpoint in Google's identity toolkit.
  DartUser.fromSignUpResponse(SignupNewUserResponse response)
      : token = response.idToken ?? '',
        email = response.email,
        uid = response.localId ?? '';

  /// The `idToken` field from API response.
  final String token;

  /// The `localId` field from API response.
  final String uid;

  /// The `email` field from API response.
  final String? email;

  /// A Map representation of this instance.
  Map<String, dynamic> toMap() => {
        'localId': uid,
        'email': email,
      };
}
