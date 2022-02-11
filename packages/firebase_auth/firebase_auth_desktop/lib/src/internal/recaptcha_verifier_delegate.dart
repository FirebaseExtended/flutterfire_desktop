import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:firebase_auth_dart/firebase_auth_dart.dart';

/// Delegate to override the default behavior of RecaptchaVerifier using [DesktopWebviewAuth].
class RecaptchaVerifierDelegate extends RecaptchaVerifier {
  /// Construct a delegate and pass empty parameters.
  RecaptchaVerifierDelegate(Map<String, dynamic> parameters)
      : super(parameters);

  @override
  Future<String?> verify(
    String? siteKey,
    String? siteToken, [
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    final result = await DesktopWebviewAuth.recaptchaVerification(
      RecaptchaArgs(siteKey: siteKey!, siteToken: siteToken!),
      height: 400,
      width: 400,
    );

    return result!.verificationId;
  }
}
