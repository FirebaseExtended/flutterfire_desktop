class RecaptchaArgs {
  final String siteKey;
  final String siteToken;

  RecaptchaArgs({
    required this.siteKey,
    required this.siteToken,
  });

  @override
  Map<String, String?> toJson() {
    return {
      'siteKey': siteKey,
      'siteToken': siteToken,
    };
  }
}
