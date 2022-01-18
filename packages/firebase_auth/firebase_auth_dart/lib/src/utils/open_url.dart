import 'dart:io';

/// A utility used to open a URL on desktop platforms.
class OpenUrlUtil {
  /// Triggers the default broswer to open a URL.
  Future<ProcessResult> openUrl(String url) {
    return Process.run(_command, [..._urlArguments, url]);
  }

  /// Triggers the default browser to open a URL.
  Future<ProcessResult> openAppUrl() {
    return Process.run(
      _command,
      [..._prefixAppArguments, _excutable, ..._suffixAppArguments],
    );
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

  String get _excutable {
    if (Platform.isWindows) {
      return '${Platform.resolvedExecutable.split('.exe')[0]}.exe';
    } else if (Platform.isLinux) {
      return '${Platform.resolvedExecutable.split('.app')[0]}.app';
    } else if (Platform.isMacOS) {
      return '${Platform.resolvedExecutable.split('.app')[0]}.app';
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

  List<String> get _prefixAppArguments {
    if (Platform.isWindows) {
      return ['start-process', '-FilePath'];
    } else {
      return [];
    }
  }

  List<String> get _suffixAppArguments {
    if (Platform.isWindows) {
      return ['-NoNewWindow'];
    } else {
      return [];
    }
  }
}
