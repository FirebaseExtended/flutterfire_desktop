// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: prefer_constructors_over_static_methods

import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'internal/recaptcha_verifier_delegate.dart';
import 'utils/desktop_utils.dart';

const String _type = 'recaptcha';

/// The delegate implementation for [RecaptchaVerifierFactoryPlatform].
///
/// This factory class is implemented to the user facing code has no underlying knowledge
/// of the delegate implementation.
class RecaptchaVerifierFactoryDesktop extends RecaptchaVerifierFactoryPlatform {
  /// Creates a new [RecaptchaVerifierFactoryDesktop] with a container and parameters.
  RecaptchaVerifierFactoryDesktop({
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) : super() {
    final parameters = <String, dynamic>{};

    if (onSuccess != null) {
      parameters['callback'] = (resp) {
        onSuccess();
      };
    }

    if (onExpired != null) {
      parameters['expired-callback'] = () {
        onExpired();
      };
    }

    if (onError != null) {
      parameters['error-callback'] = (Object error) {
        onError(getFirebaseAuthException(error));
      };
    }

    parameters['size'] = size.name;
    parameters['theme'] = theme.name;

    _delegate = RecaptchaVerifierDelegate(parameters);
  }

  RecaptchaVerifierFactoryDesktop._() : super();

  late auth_dart.RecaptchaVerifier _delegate;

  @override
  RecaptchaVerifierFactoryPlatform delegateFor({
    required FirebaseAuthPlatform auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) {
    return RecaptchaVerifierFactoryDesktop(
      size: size,
      theme: theme,
      onSuccess: onSuccess,
      onError: onError,
      onExpired: onExpired,
    );
  }

  /// Returns a stub instance of the class.
  ///
  /// This is used during initialization of the plugin so the user-facing
  /// code has access to the class instance without directly knowing about it.
  ///
  // ignore: comment_references
  /// See the [registerWith] static method on the [FirebaseAuthDesktop] class.
  static RecaptchaVerifierFactoryDesktop get instance =>
      RecaptchaVerifierFactoryDesktop._();

  @override
  auth_dart.RecaptchaVerifier get delegate {
    return _delegate;
  }

  @override
  String get type => _type;

  @override
  void clear() {}
}
