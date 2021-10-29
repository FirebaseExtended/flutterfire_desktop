// ignore_for_file: require_trailing_commas, avoid_dynamic_calls
part of '../flutterfire_functions_dart.dart';

/// Pure Dart service layer to perform all requests
class API {
  // ignore: public_member_api_docs
  API(this._apiKey, this._projectId, {http.Client? client});

  late final String _apiKey;
  late final String _projectId;

  late http.Client _client;

  void _setApiClient(http.Client client) {
    _client = client;
  }

  /// TODO: write endpoint details
  Future<Map> useEmulator(String host, int port) async {
    // 1. Get the emulator project configs, it must be initialized first.
    // http://localhost:9099/emulator/v1/projects/{project-id}/config
    final localEmulator = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: '/emulator/v1/projects/$_projectId/config',
    );

    http.Response response;

    try {
      response = await http.get(localEmulator);
    } on SocketException catch (e) {
      final socketException = SocketException(
        'Error happened while trying to connect to the local emulator, '
        'make sure you have it running, and you provided the correct port.',
        port: port,
        osError: e.osError,
        address: e.address,
      );

      throw socketException;
    } catch (e) {
      rethrow;
    }

    final Map emulatorProjectConfig = json.decode(response.body);

    // 3. Update the requester to use emulator

    return emulatorProjectConfig;
  }
}
