// ignore_for_file: require_trailing_commas

part of api;

/// A return type from Idp phone authentication requests.
@protected
class SignInWithPhoneNumberResponse extends IdTokenResponse {
  /// Construct a new [IdTokenResponse].
  SignInWithPhoneNumberResponse({
    required String idToken,
    required String refreshToken,
    required this.phoneNumber,
    this.isNewUser,
  }) : super(idToken: idToken, refreshToken: refreshToken);

  /// The phone number used to sign in.
  final String phoneNumber;

  /// Wether this user is using phone authentication for the first time or is a returning user.
  final bool? isNewUser;

  @override
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'refreshToken': refreshToken,
      'phoneNumber': phoneNumber,
      'isNewUser': isNewUser,
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
  Future<String> signInWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
    Duration timeout = const Duration(seconds: 30),
  ]) async {
    Future<String> _verifyAction;

    if (api._emulator != null) {
      _verifyAction = _verifyEmulator(phoneNumber, timeout);
    } else {
      verifier ??= _recaptchaVerifier;
      _verifyAction = _verify(phoneNumber, verifier, timeout);
    }

    return _verifyAction;
  }

  /// TODO: write endpoint details
  Future<SignInWithPhoneNumberResponse> confirmSMSCode(
      String smsCode, String verificationId,
      [String? idToken]) async {
    final _response = await api._identityToolkit.verifyPhoneNumber(
      idp.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
        code: smsCode,
        sessionInfo: verificationId,
        idToken: idToken,
      ),
    );

    return SignInWithPhoneNumberResponse(
      idToken: _response.idToken!,
      phoneNumber: _response.phoneNumber!,
      refreshToken: _response.refreshToken!,
      isNewUser: _response.isNewUser,
    );
  }

  Future<String> _verify(
      String phoneNumber, RecaptchaVerifier verifier, Duration timeout) async {
    final completer = Completer<String>();

    final recaptchaResponse = await api._identityToolkit.getRecaptchaParam();

    final recaptchaToken = await verifier
        .verify(
          recaptchaResponse.recaptchaSiteKey,
          recaptchaResponse.recaptchaStoken,
          timeout,
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

  Future<String> _verifyEmulator(String phoneNumber, Duration timeout) async {
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
