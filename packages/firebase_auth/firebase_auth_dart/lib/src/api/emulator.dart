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

/// Call the local auth emulator.
/// If found, set the instance API to use it for all future requests.
class AuthEmulator {
  // ignore: public_member_api_docs
  AuthEmulator(this._config);

  final APIConfig _config;

  /// Try to connect to the local runnning emulator by getting emulator-specific
  /// configuration for the specified project. If the connection was successful,
  /// set local emulator in API configurations to be used for all future requests.
  Future<Map<String, dynamic>> useEmulator(String host, int port) async {
    // 1. Get the emulator project configs, it must be initialized first.
    // http://localhost:9099/emulator/v1/projects/{project-id}/config
    final localEmulator = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: '/emulator/v1/projects/${_config.projectId}/config',
    );

    http.Response response;

    try {
      response = await http.get(localEmulator);
    } catch (e) {
      return {};
    }

    final Map<String, dynamic> emulatorProjectConfig =
        json.decode(response.body);

    // set the the emulator config for this instance.
    _config.setEmulator(host, port);

    return emulatorProjectConfig;
  }
}
