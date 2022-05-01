part of api;

/// A return type from Idp phone authentication requests.
@internal
class SignInWithPhoneNumberResponse extends SignInResponse {
  /// Construct a new [SignInWithPhoneNumberResponse].
  SignInWithPhoneNumberResponse._({
    required String idToken,
    required String refreshToken,
    required this.phoneNumber,
    this.verificationId,
    this.temporaryProof,
    bool isNewUser = false,
  }) : super(
          idToken,
          refreshToken,
          isNewUser,
        );

  /// Construct new [SignInWithPhoneNumberResponse] from a sign-in json result.
  factory SignInWithPhoneNumberResponse.fromJson(Map<String, dynamic> json) {
    return SignInWithPhoneNumberResponse._(
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      phoneNumber: json['phoneNumber'] as String,
      verificationId: json['verificationId'],
      temporaryProof: json['temporaryProof'],
      isNewUser: (json['isNewUser'] as bool?) ?? false,
    );
  }

  /// The phone number used to sign in.
  final String phoneNumber;

  /// The Id returned after SMS code is sent to the phone number.
  final String? verificationId;

  /// If not null, it indicates that the phone number is assigned to another account under different credentials.
  final String? temporaryProof;

  @override
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'refreshToken': refreshToken,
      'phoneNumber': phoneNumber,
      'verificationId': verificationId,
      'temporaryProof': temporaryProof,
      'isNewUser': isNewUser,
    };
  }
}

/// Class wrapping methods that calls to the following endpoints:
/// - `verifyPhoneNumber`: verify a phone number using a verification id and sms code.
/// - `sendVerificationCode`: send an sms login code.
@internal
class SmsAuth extends APIDelegate {
  // ignore: public_member_api_docs
  SmsAuth(API api) : super(api);

  /// Default Recaptcha theme. Could be overridden if user passed a `verifier` to [signInWithPhoneNumber].
  final _recaptchaVerifier =
      RecaptchaVerifier({'theme': RecaptchaTheme.light.name});

  /// Sign in using Phone Number with a [RecaptchaVerifier].
  ///
  /// If the emulator is running, the recaptcha verification will be skipped.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `verification-canceled`: The user canceled the verification process
  Future<String> signInWithPhoneNumber(
    String phoneNumber, {
    RecaptchaVerifier? verifier,
  }) async {
    try {
      Future<String> _verifyAction;

      if (api.apiConfig.emulator != null) {
        _verifyAction = _verifyEmulator(phoneNumber);
      } else {
        verifier ??= _recaptchaVerifier;
        _verifyAction = _verify(phoneNumber, verifier);
      }

      return _verifyAction;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  /// Confirm a phone number belongs to a user via SMS code.
  /// The response will contain a fresh `idToken` and a `refreshToken`.
  ///
  /// Common error codes:
  /// - `NEED_CONFIRMATION`: The phone number is already used by another account.
  /// - `INVALID_CODE`: The provided code is not valid.
  Future<SignInWithPhoneNumberResponse> confirmPhoneNumber({
    String? phoneNumber,
    String? smsCode,
    String? verificationId,
    String? idToken,
    String? temporaryProof,
  }) async {
    try {
      final response = await api.identityToolkit.verifyPhoneNumber(
        IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
          code: smsCode,
          sessionInfo: verificationId,
          idToken: idToken,
          phoneNumber: phoneNumber,
          temporaryProof: temporaryProof,
        ),
      );

      if (response.temporaryProof != null) {
        // We throw the exception manually since it's not considered as an exception by the IDP package.
        throw DetailedApiRequestError(null, 'NEED_CONFIRMATION');
      }

      return SignInWithPhoneNumberResponse.fromJson(response.toJson());
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }

  Future<String> _verify(String phoneNumber, RecaptchaVerifier verifier) async {
    final completer = Completer<String>();

    final recaptchaResponse = await api.identityToolkit.getRecaptchaParam();

    final recaptchaArgs = RecaptchaArgs(
      siteKey: recaptchaResponse.recaptchaSiteKey!,
      siteToken: recaptchaResponse.recaptchaStoken!,
    );

    final recaptchaToken = await verifier.verify(recaptchaArgs);

    if (recaptchaToken == null) {
      // This's not an exception coming from the IDP package,
      // but for consistency we throw it as if it's coming from the package.
      throw DetailedApiRequestError(null, 'VERIFICATION_CANCELED');
    }

    try {
      final verificationId = await _sendSMSCode(
        phoneNumber: phoneNumber,
        recaptchaToken: recaptchaToken,
      );

      completer.complete(verificationId);
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<String> _verifyEmulator(String phoneNumber) async {
    final completer = Completer<String>();

    try {
      final verificationId = await _sendSMSCode(phoneNumber: phoneNumber);
      completer.complete(verificationId);
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<String?> _sendSMSCode({
    required String phoneNumber,
    String? recaptchaToken,
  }) async {
    try {
      // Send SMS code.
      final response = await api.identityToolkit.sendVerificationCode(
        IdentitytoolkitRelyingpartySendVerificationCodeRequest(
          phoneNumber: phoneNumber,
          recaptchaToken: recaptchaToken,
        ),
      );

      return response.sessionInfo;
    } on DetailedApiRequestError catch (e) {
      throw makeAuthException(e);
    }
  }
}
