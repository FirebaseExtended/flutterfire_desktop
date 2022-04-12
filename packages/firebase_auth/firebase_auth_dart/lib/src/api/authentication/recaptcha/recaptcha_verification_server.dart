part of api;

/// Request recaptcha verification on the local server.
class RecaptchaVerificationServer {
  /// Construct a new recaptcha verification server using the passed recaptcha arguments.
  RecaptchaVerificationServer(this.args);

  /// Recaptcha verification arguments needed to render recaptcha widget.
  final RecaptchaArgs args;

  /// The url on which the server is currently running.
  late final String url;

  late void Function(Exception e) _onError;
  late void Function(String? res) _onResponse;

  late final HttpServer _server;

  /// Pass a new callback to run on errors.
  // ignore: avoid_setters_without_getters
  set onError(void Function(Exception e) callback) {
    _onError = callback;
  }

  /// Pass a new callback to run on errors.
  // ignore: avoid_setters_without_getters
  set onResponse(void Function(String? res) callback) {
    _onResponse = callback;
  }

  /// Start a local server.
  Future<void> start() async {
    final address = InternetAddress.loopbackIPv4;
    _server = await HttpServer.bind(address, 0);

    _server.listen((req) async {
      try {
        final res = req.response;
        final body = _handleRequest(req);

        if (body == null) {
          res
            ..statusCode = 404
            ..write('Not found');
        } else {
          res
            ..statusCode = 200
            ..headers.add('content-type', 'text/html')
            ..write(body);
        }

        await res.close();
      } on Exception catch (e) {
        _onError(e);
      }
    });

    url = 'http://${address.host}:${_server.port}';
  }

  /// Close the currently running server.
  Future<void> close() async {
    await _server.close();
  }

  String? _handleRequest(HttpRequest req) {
    final uri = req.requestedUri;

    if (uri.path == '/' && uri.queryParameters.isEmpty) {
      return recaptchaHTML(args.siteKey, args.siteToken);
    }

    if (uri.query.contains('response')) {
      Future.microtask(() {
        _onResponse(uri.queryParameters['response']);
      });

      return responseHTML(
        'Success',
        'Successful verification!',
      );
    }

    if (uri.query.contains('error-code')) {
      Future.microtask(() {
        _onError(Exception(uri.queryParameters['error-code']));
      });

      return responseHTML(
        'Captcha check failed.',
        '${uri.queryParameters['error-code']}',
      );
    }

    return null;
  }
}
