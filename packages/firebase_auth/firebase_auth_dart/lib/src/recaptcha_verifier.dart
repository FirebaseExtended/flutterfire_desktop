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

/// Initiate and setup recaptcha flow on Desktop platforms.
class RecaptchaVerifier {
  // ignore: public_member_api_docs
  RecaptchaVerifier(this.parameters);

  /// List of parameters passed to captcha check request.
  final Map<String, dynamic> parameters;

  String? _verificationId;

  /// The verificationId of this session.
  String? get verificationId => _verificationId;

  /// Kick-off the recaaptcha verifier and listen to changes emitted by [HttpRequest].
  ///
  /// Each event represents the current state of the verification in the broswer.
  ///
  /// On desktop platforms calling this method will fire up the default browser.
  Future<String?> verify(
    String? siteKey,
    String? siteToken, [
    Duration timeout = const Duration(seconds: 30),
  ]) async {
    final completer = Completer<String?>();
    final address = InternetAddress.loopbackIPv4;
    final server = await HttpServer.bind(address, 0);
    final port = server.port;
    final redirectUrl = 'http://${address.host}:$port';

    server.listen((HttpRequest request) async {
      final uri = request.requestedUri;

      if (uri.path == '/' && uri.queryParameters.isEmpty) {
        await _sendDataToHTTP(
          request,
          recaptchaHTML(
            siteKey,
            siteToken,
            theme: parameters['theme'],
            size: parameters['size'],
          ),
        );
      } else if (uri.query.contains('response')) {
        await _sendDataToHTTP(
          request,
          responseHTML(
            'Success',
            'Successful verification! you may close this window now.',
          ),
        );

        _verificationId = uri.queryParameters['response'];

        // ignore: avoid_dynamic_calls
        if (parameters.containsKey('callback')) {
          // ignore: avoid_dynamic_calls
          parameters['callback']();
        }

        await server.close();

        completer.complete(_verificationId);
      } else if (uri.query.contains('error-code')) {
        await _sendDataToHTTP(
          request,
          responseHTML(
            'Error',
            uri.queryParameters['error-code']!,
          ),
        );
        if (parameters.containsKey('callback-error')) {
          // ignore: avoid_dynamic_calls
          parameters['callback-error']();
        }

        await server.close();

        completer.completeError((e) {
          return Exception(uri.queryParameters['error-code']);
        });
      }
    });

    await OpenUrlUtil().openUrl(redirectUrl);

    return completer.future.timeout(timeout);
  }

  Future<void> _sendDataToHTTP(
    HttpRequest request,
    Object data, [
    String contentType = 'text/html',
  ]) async {
    request.response
      ..statusCode = 200
      ..headers.set('content-type', contentType)
      ..write(data);
    await request.response.close();
  }
}
