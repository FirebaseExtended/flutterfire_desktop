part of '../../firebase_remote_config_dart.dart';

class _RemoteConfigStorage {
  final StorageBox _options = StorageBox.instanceOf('remote_config');
  static const activeConfigKey = 'active_config';
  // TODO: Finish storage
  static const activeConfigEtagKey = 'active_config_etag';
  static const lastFetchStatusKey = 'last_fetch_status';
  static const lastSuccessfulFetchTimeKey =
      'last_successful_fetch_timestamp_millis';
  static const lastSuccessfulFetchKey = 'last_successful_fetch_response';
  static const settingsKey = 'settings';
  static const throttleMetadataKey = 'throttle_metadata';

  /// The latest cached config loaded from storage or the server
  Map<String, RemoteConfigValue> _lastFetchedConfig = {};

  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime get lastFetchTime => _lastFetchTime;

  RemoteConfigFetchStatus _lastFetchStatus = RemoteConfigFetchStatus.noFetchYet;
  RemoteConfigFetchStatus get lastFetchStatus => _lastFetchStatus;

  Future<void> loadFromStorage() async {
    final config = _options.getValue(activeConfigKey) as Map<String, Object?>;
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
      activeConfigKey,
      {for (final entry in config.entries) entry.key: entry.value.toJson()},
    );
  }
}

extension _RemoteConfigJson on RemoteConfigValue {
  static RemoteConfigValue fromJson(Map<String, Object?> remoteConfigValue) {
    return RemoteConfigValue(
      const Utf8Codec().encode(
        remoteConfigValue['value']! as String,
      ),
      ValueSource.values.byName(remoteConfigValue['source']! as String),
    );
  }

  Map<String, Object?> toJson() {
    return {'source': source.name, 'value': asString()};
  }
}
