// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'recaptcha_html.dart';
import 'utils/open_url.dart';

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
  RecaptchaVerifier(this.siteKey, this.siteToken, {this.theme});

  /// Site Key used to initialize recaptcha.
  final String? siteKey;

  /// Site token used to initialize recaptcha.
  final String? siteToken;

  /// The theme of the rendered recaptcha widget.
  final RecaptchaTheme? theme;

  String? _verificationId;

  /// The verificationId of this session.
  String? get verificationId => _verificationId;

  final _tokenStream = StreamController<String?>.broadcast();

  /// Kick-off the recaaptcha verifier and listen to changes emitted by [HttpRequest].
  ///
  /// Each event represents the current state of the verification in the broswer.
  ///
  /// On desktop platforms calling this method will fire up the default browser,
  /// in most cases the recaptcha will happen in few seconds without user interaction,
  /// but sometimes will show the recaptcha widget.
  Stream<String?> excute() async* {
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
            theme: theme?.name,
          ),
        );
      } else if (uri.query.contains('response')) {
        await _sendDataToHTTP(
          request,
          successHTML(),
        );

        _verificationId = uri.queryParameters['response'];

        _tokenStream.add(_verificationId);

        await server.close();
        await _tokenStream.close();
      }
    });

    await OpenUrlUtil().openUrl(redirectUrl);

    yield _verificationId;
    yield* _tokenStream.stream;
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
