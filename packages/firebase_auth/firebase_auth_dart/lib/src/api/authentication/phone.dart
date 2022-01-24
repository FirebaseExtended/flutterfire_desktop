// ignore_for_file: require_trailing_commas

part of api;

/// A return type from Idp phone authentication requests.
@protected
class SignInWithPhoneNumberResponse {
  /// Construct a new [IdTokenResponse].
  SignInWithPhoneNumberResponse({
    required this.phoneNumber,
    required this.verificationId,
  });

  /// The phone number used to sign in.
  final String phoneNumber;

  /// The Id returned after SMS code is sent to the phone number.
  final String verificationId;

  /// Json representation of this object.
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'verificationId': verificationId,
    };
  }
}

/// The instance used for phone authentication with idp.
@internal
class PhoneAuthAPI {
  /// Construct a new [PhoneAuthAPI].
  PhoneAuthAPI(this.api);

  /// The [API] instance containing required configurations to make the requests.
  API api;

  RecaptchaVerifier _recaptchaVerifier =
      RecaptchaVerifier({'theme': RecaptchaTheme.light.name});

  /// Override the default `RecaptchaVerifier` to allow rendering with different theme.
  // ignore: avoid_setters_without_getters
  set setRecaptchaVerifier(RecaptchaVerifier recaptchaVerifier) {
    _recaptchaVerifier = recaptchaVerifier;
  }

  /// TODO: write endpoint details
  Future<SignInWithPhoneNumberResponse> signInWithPhoneNumber(
    String phoneNumber, {
    String? idToken,
    RecaptchaVerifier? verifier,
  }) async {
    Future<String> _verifyAction;

    if (api._emulator != null) {
      _verifyAction = _verifyEmulator(phoneNumber);
    } else {
      verifier ??= _recaptchaVerifier;
      _verifyAction = _verify(phoneNumber, verifier);
    }

    return SignInWithPhoneNumberResponse(
      phoneNumber: phoneNumber,
      verificationId: await _verifyAction,
    );
  }

  /// TODO: write endpoint details
  Future<SignInWithPhoneNumberResponse> linkWithPhoneNumber(
    String idToken,
    String phoneNumber, {
    RecaptchaVerifier? verifier,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final signInResponse = await signInWithPhoneNumber(
      phoneNumber,
      idToken: idToken,
      verifier: verifier,
    );

    return signInResponse;
  }

  /// TODO: write endpoint details
  Future<idp.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse>
      verifyPhoneNumber({
    String? phoneNumber,
    String? smsCode,
    String? verificationId,
    String? idToken,
    String? temporaryProof,
  }) async {
    try {
      final response = await api._identityToolkit.verifyPhoneNumber(
        idp.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
          code: smsCode,
          sessionInfo: verificationId,
          idToken: idToken,
          phoneNumber: phoneNumber,
          temporaryProof: temporaryProof,
        ),
      );

      if (response.temporaryProof != null) {
        throw FirebaseAuthException(code: 'NEED_CONFIRMATION');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _verify(String phoneNumber, RecaptchaVerifier verifier) async {
    final completer = Completer<String>();

    final recaptchaResponse = await api._identityToolkit.getRecaptchaParam();

    final recaptchaToken = await verifier
        .verify(
          recaptchaResponse.recaptchaSiteKey,
          recaptchaResponse.recaptchaStoken,
        )
        .whenComplete(() => unawaited(OpenUrlUtil().openAppUrl()));
    if (recaptchaToken != null) {
      try {
        final verificationId = await _sendSMSCode(
          phoneNumber: phoneNumber,
          recaptchaToken: recaptchaToken,
        );
        completer.complete(verificationId);
      } catch (e) {
        completer.completeError(e);
      }
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
    } finally {
      unawaited(OpenUrlUtil().openAppUrl());
    }

    return completer.future;
  }

  Future<String?> _sendSMSCode(
      {required String phoneNumber, String? recaptchaToken}) async {
    try {
      // Send SMS code.
      final response = await api._identityToolkit.sendVerificationCode(
        idp.IdentitytoolkitRelyingpartySendVerificationCodeRequest(
          phoneNumber: phoneNumber,
          recaptchaToken: recaptchaToken,
        ),
      );

      if (response.sessionInfo != null) {
        return response.sessionInfo;
      }
    } catch (e) {
      rethrow;
    }
  }
}
