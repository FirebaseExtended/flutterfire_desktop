// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:googleapis/identitytoolkit/v3.dart' as idp;
import 'package:meta/meta.dart';

import '../../firebase_auth_exception.dart';
import '../../utils/open_url.dart';
import '../api.dart';
import 'recaptcha.dart';

/// A return type from Idp phone authentication requests.
@internal
class SignInWithPhoneNumberResponse {
  /// Construct a new [IdTokenResponse].
  SignInWithPhoneNumberResponse({
    required this.phoneNumber,
    this.verificationId,
    this.idToken,
    this.temporaryProof,
    this.isNewUser,
  });

  /// The phone number used to sign in.
  final String phoneNumber;

  /// Fresh idToken after sign in with phone number is verified.
  final String? idToken;

  /// The Id returned after SMS code is sent to the phone number.
  final String? verificationId;

  /// If not null, it indicates that the phone number is assigned to another account under different credentials.
  final String? temporaryProof;

  /// Wether this user is newly registered or not.
  final bool? isNewUser;

  /// Json representation of this object.
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'verificationId': verificationId,
      'idToken': idToken,
      'temporaryProof': temporaryProof,
      'isNewUser': isNewUser,
    };
  }
}

/// The instance used for phone authentication with idp.
@internal
class PhoneAuthAPI {
  /// Construct a new [PhoneAuthAPI].
  PhoneAuthAPI(this._api);

  /// The [API] instance containing required configurations to make the requests.
  final API _api;

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

    if (_api.apiConfig.emulator != null) {
      _verifyAction = _verifyEmulator(phoneNumber);
    } else {
      verifier ??= _recaptchaVerifier;
      _verifyAction = _verify(phoneNumber, verifier);
    }

    return SignInWithPhoneNumberResponse(
      phoneNumber: phoneNumber,
      verificationId: await _verifyAction,
      idToken: idToken,
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
  Future<SignInWithPhoneNumberResponse> verifyPhoneNumber({
    String? phoneNumber,
    String? smsCode,
    String? verificationId,
    String? idToken,
    String? temporaryProof,
  }) async {
    try {
      final response = await _api.identityToolkit.verifyPhoneNumber(
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

      return SignInWithPhoneNumberResponse(
        phoneNumber: response.phoneNumber!,
        idToken: response.idToken,
        temporaryProof: response.temporaryProof,
        isNewUser: response.isNewUser,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _verify(String phoneNumber, RecaptchaVerifier verifier) async {
    final completer = Completer<String>();

    final recaptchaResponse = await _api.identityToolkit.getRecaptchaParam();

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
      final response = await _api.identityToolkit.sendVerificationCode(
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
