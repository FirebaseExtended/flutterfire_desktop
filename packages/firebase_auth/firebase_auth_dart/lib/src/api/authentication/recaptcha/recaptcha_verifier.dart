// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../../../utils/open_url.dart';
import 'recaptcha_args.dart';
import 'recaptcha_verification_server.dart';

/// The theme of the rendered recaptcha widget.
enum RecaptchaTheme {
  /// Light mode.
  light,

  /// Dark mode.
  dark
}

/// Initiate and setup recaptcha flow.
class RecaptchaVerifier {
  // ignore: public_member_api_docs
  RecaptchaVerifier(this.parameters);

  /// List of parameters passed to captcha check request.
  final Map<String, dynamic> parameters;

  String? _verificationId;

  /// The verificationId of this session.
  String? get verificationId => _verificationId;

  /// Kick-off the recaptcha verifier and listen to changes emitted by [HttpRequest].
  ///
  /// Each event represents the current state of the verification in the broswer.
  ///
  /// On desktop platforms calling this method will fire up the default browser.
  Future<String?> verify(
    RecaptchaArgs args, [
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    final completer = Completer<String?>();

    final server = RecaptchaVerificationServer(args);

    server.onError = completer.completeError;

    await server.start();

    // server.listen((request) async {
    //   final uri = request.requestedUri;

    //   log(uri.path);

    //   if (uri.path == '/' && uri.queryParameters.isEmpty) {
    //     await _sendDataToHTTP(
    //       request,
    //       recaptchaHTML(
    //         siteKey,
    //         siteToken,
    //         theme: parameters['theme'],
    //         size: parameters['size'],
    //       ),
    //     );
    //   } else if (uri.query.contains('response')) {
    //     await _sendDataToHTTP(
    //       request,
    //       responseHTML(
    //         'Success',
    //         'Successful verification!',
    //       ),
    //     );

    //     _verificationId = uri.queryParameters['response'];

    //     // ignore: avoid_dynamic_calls
    //     if (parameters.containsKey('callback')) {
    //       // ignore: avoid_dynamic_calls
    //       parameters['callback']();
    //     }

    //     completer.complete(_verificationId);
    //   } else if (uri.query.contains('error-code')) {
    //     await _sendDataToHTTP(
    //       request,
    //       responseHTML(
    //         'Captcha check failed.',
    //         uri.queryParameters['error-code']!,
    //       ),
    //     );

    //     completer.completeError((e) {
    //       if (parameters.containsKey('callback-error')) {
    //         // ignore: avoid_dynamic_calls
    //         parameters['callback-error'](e);
    //       }

    //       return Exception(uri.queryParameters['error-code']);
    //     });
    //   }
    // });

    await OpenUrlUtil().openUrl(server.url);

    return completer.future.whenComplete(server.close).timeout(
      timeout,
      onTimeout: () {
        server.close();
        return null;
      },
    );
  }
}
