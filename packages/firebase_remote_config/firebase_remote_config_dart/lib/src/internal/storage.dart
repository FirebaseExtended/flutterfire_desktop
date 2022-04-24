part of '../../firebase_remote_config_dart.dart';

class _RemoteConfigStorage {
  final StorageBox _options = StorageBox.instanceOf('remote_config');

  /// The last fetched config
  Map<String, RemoteConfigValue> _lastFetchedConfig = {};

  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime get lastFetchTime => _lastFetchTime;

  RemoteConfigFetchStatus _lastFetchStatus = RemoteConfigFetchStatus.noFetchYet;
  RemoteConfigFetchStatus get lastFetchStatus => _lastFetchStatus;

  Future<void> load() async {
    final config = _options.getValue('lastFetchConfig') as Map<String, Object?>;
    _lastFetchedConfig = {
      for (final entry in config.entries)
        if (entry.value != null)
          entry.key:
              _RemoteConfigJson.fromJson(entry.value! as Map<String, Object?>)
    };
  }

  void update(Map<String, RemoteConfigValue> config) {
    _lastFetchTime = DateTime.now();
    _lastFetchStatus = RemoteConfigFetchStatus.success;
    _lastFetchedConfig = config;
    _options.putValue(
      'lastFetchConfig',
      {for (final entry in config.entries) entry.key: entry.value.toJson()},
    );
  }
}

extension _RemoteConfigJson on RemoteConfigValue {
  static RemoteConfigValue fromJson(Map<String, Object?> remoteConfigValue) {}
  Map<String, Object?> toJson() {}
}
