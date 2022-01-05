import 'dart:io';

/// A utility used to open a URL on desktop platforms.
class OpenUrlUtil {
  /// Triggers the default broswer to open a URL.
  Future<ProcessResult> openUrl(String url) {
    return Process.run(_command, [url], runInShell: true);
  }

  String get _command {
    if (Platform.isWindows) {
      return 'start';
    } else if (Platform.isLinux) {
      return 'xdg-open';
    } else if (Platform.isMacOS) {
      return 'open';
    } else {
      throw UnsupportedError(
        'Operating system not supported by the open_url '
        'package: ${Platform.operatingSystem}',
      );
    }
  }
}
