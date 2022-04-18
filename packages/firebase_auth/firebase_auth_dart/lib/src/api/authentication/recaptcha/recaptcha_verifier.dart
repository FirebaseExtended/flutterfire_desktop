// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

part of api;

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
    server.onResponse = completer.complete;

    await server.start();

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
