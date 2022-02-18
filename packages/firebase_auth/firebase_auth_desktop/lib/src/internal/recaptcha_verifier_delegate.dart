import 'dart:io';

import 'package:desktop_webview_auth/desktop_webview_auth.dart' as webview;
import 'package:firebase_auth_dart/firebase_auth_dart.dart';

/// Delegate to override the default behavior of RecaptchaVerifier using [webview.DesktopWebviewAuth].
class RecaptchaVerifierDelegate extends RecaptchaVerifier {
  /// Construct a delegate and pass empty parameters.
  RecaptchaVerifierDelegate(Map<String, dynamic> parameters)
      : super(parameters);

  @override
  Future<String?> verify(
    RecaptchaArgs args, [
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    // TODO(pr-mais): remove once `desktop_webview_auth` supports windows.
    if (Platform.isWindows) {
      final result = await super.verify(args);
      return result;
    }

    final result = await webview.DesktopWebviewAuth.recaptchaVerification(
      webview.RecaptchaArgs(
        siteKey: args.siteKey,
        siteToken: args.siteToken,
      ),
      height: 500,
      width: 600,
    );

    return result?.verificationId;
  }
}
