// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas, avoid_returning_this, prefer_relative_imports, non_constant_identifier_names

import 'package:firebase_auth_dart/firebase_auth_dart.dart';

const _kProviderId = 'phone';

/// This class should be used to either create a new Phone credential with a
/// verification ID and SMS code.
class PhoneAuthProvider extends AuthProvider {
  /// Creates a new instance.
  PhoneAuthProvider() : super(_kProviderId);

  // ignore: public_member_api_docs
  static String get PHONE_SIGN_IN_METHOD {
    return _kProviderId;
  }

  // ignore: public_member_api_docs
  static String get PROVIDER_ID {
    return _kProviderId;
  }

  /// Create a new [PhoneAuthCredential] from a provided [verificationId] and
  /// [smsCode].
  static PhoneAuthCredential credential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthCredential._credential(verificationId, smsCode);
  }

  /// Create a [PhoneAuthCredential] from an internal token, where the ID
  /// relates to a natively stored credential.
  static PhoneAuthCredential credentialFromToken(int token, {String? smsCode}) {
    return PhoneAuthCredential._credentialFromToken(smsCode: smsCode);
  }
}

/// The auth credential returned from calling
/// [PhoneAuthProvider.credential].
class PhoneAuthCredential extends AuthCredential {
  PhoneAuthCredential._({
    this.verificationId,
    this.smsCode,
    //int? token,
  }) : super(
          providerId: _kProviderId,
          signInMethod: _kProviderId,
          //token: token,
        );

  factory PhoneAuthCredential._credential(
      String verificationId, String smsCode) {
    return PhoneAuthCredential._(
        verificationId: verificationId, smsCode: smsCode);
  }

  factory PhoneAuthCredential._credentialFromToken({
    String? smsCode,
  }) {
    return PhoneAuthCredential._(smsCode: smsCode);
  }

  /// The phone auth verification ID.
  final String? verificationId;

  /// The SMS code sent to and entered by the user.
  final String? smsCode;

  /// Returns the credential as a serialized [Map].
  @override
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'signInMethod': signInMethod,
      'verificationId': verificationId,
      'smsCode': smsCode,
      //'token': token,
    };
  }
}
