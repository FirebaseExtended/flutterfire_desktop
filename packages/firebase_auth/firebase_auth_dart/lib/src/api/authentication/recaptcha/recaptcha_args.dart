part of api;

/// Recaptcha verification arguments needed to render recaptcha widget.
class RecaptchaArgs {
  /// Construct new RecaptchaArgs.
  RecaptchaArgs({
    required this.siteKey,
    required this.siteToken,
  });

  /// Site key registered at recaptcha.
  final String siteKey;

  /// The stoken field for the recaptcha widget, used to request captcha challenge.
  final String siteToken;
}
