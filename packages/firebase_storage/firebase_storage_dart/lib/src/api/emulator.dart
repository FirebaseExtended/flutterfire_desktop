part of api;

/// A type to hold the Auth Emulator configurations.
class EmulatorConfig {
  EmulatorConfig._({
    required this.port,
    required this.host,
  });

  /// Initialize the Emulator Config using the host and port printed once running `firebase emulators:start`.
  factory EmulatorConfig.use(String host, int port) {
    return EmulatorConfig._(port: port, host: host);
  }

  /// The port on which the emulator suite is running.
  final String host;

  /// The port on which the emulator suite is running.
  final int port;

  /// The root URL used to make requests to the locally running emulator.
  String get rootUrl => 'http://$host:$port/www.googleapis.com/';
}
