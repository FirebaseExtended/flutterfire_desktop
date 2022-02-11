import 'dart:io';

/// A utility used to open a URL on desktop platforms.
class OpenUrlUtil {
  /// Triggers the default broswer to open a URL.
  Future<ProcessResult> openUrl(String url) {
    return Process.run(_command, [..._urlArguments, url]);
  }

  String get _command {
    if (Platform.isWindows) {
      return 'powershell';
    } else if (Platform.isLinux) {
      return 'xdg-open';
    } else if (Platform.isMacOS) {
      return 'open';
    } else {
      throw UnsupportedError(
        'Operating system not supported ${Platform.operatingSystem}',
      );
    }
  }

  List<String> get _urlArguments {
    if (Platform.isWindows) {
      return ['start-process'];
    } else {
      return [];
    }
  }
}
