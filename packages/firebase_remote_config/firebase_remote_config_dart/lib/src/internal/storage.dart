part of '../../firebase_remote_config_dart.dart';

class _RemoteConfigStorage {
  _RemoteConfigStorage(this.appId, this.appName, this.namespace);
  final String appId;
  final String appName;
  final String namespace;
  final StorageBox _storageBox =
      StorageBox.instanceOf('firebase_remote_config');
  static const activeConfigKey = 'active_config';
  static const lastFetchStatusKey = 'last_fetch_status';
  static const lastSuccessfulFetchTimeKey =
      'last_successful_fetch_timestamp_millis';
  // TODO: Finish storage
  static const activeConfigEtagKey = 'active_config_etag';
  static const lastSuccessfulFetchKey = 'last_successful_fetch_response';
  static const settingsKey = 'settings';
  static const throttleMetadataKey = 'throttle_metadata';

  /// The latest cached config loaded from storage or the server
  final Map<String, RemoteConfigValue> _lastFetchedConfig = {};

  DateTime? get lastFetchTime =>
      (_storageBox.getValue(lastSuccessfulFetchTimeKey) as int?)
          .mapNullable(DateTime.fromMicrosecondsSinceEpoch);

  /// Sets the last fetch time
  set lastFetchTime(DateTime? value) {
    _storageBox.putValue(
      lastSuccessfulFetchTimeKey,
      value?.microsecondsSinceEpoch,
    );
  }

  RemoteConfigFetchStatus? get lastFetchStatus =>
      (_storageBox.getValue(lastFetchStatusKey) as String?)
          .mapNullable(RemoteConfigFetchStatus.values.byName);

  /// Sets the last fetch status
  set lastFetchStatus(RemoteConfigFetchStatus? value) {
    _storageBox.putValue(lastFetchStatusKey, value);
  }

  Map<String, RemoteConfigValue>? get activeConfig {
    final config =
        _storageBox.getValue(activeConfigKey) as Map<String, Object?>?;
    if (config == null) {
      return null;
    }
    return {
      for (final entry in config.entries)
        if (entry.value != null)
          entry.key:
              _RemoteConfigJson.fromJson(entry.value! as Map<String, Object?>)
    };
  }

  set activeConfig(Map<String, RemoteConfigValue>? config) {
    _storageBox.putValue(
      activeConfigKey,
      config == null
          ? null
          : {
              for (final entry in config.entries)
                entry.key: entry.value.toJson(),
            },
    );
  }
}

/// A memory cache layer over storage to support the SDK's synchronous read requirements.
class _RemoveConfigStorageCache {
  _RemoveConfigStorageCache(_RemoteConfigStorage storage) : _storage = storage;
  final _RemoteConfigStorage _storage;

  /// Memory caches.

  /// The cached last fetch status
  RemoteConfigFetchStatus? get lastFetchStatus => _lastFetchStatus;
  RemoteConfigFetchStatus? _lastFetchStatus;

  /// The cached last fetch time
  DateTime? get lastFetchTime => _lastFetchTime;
  DateTime? _lastFetchTime;

  /// The cached last active config
  Map<String, RemoteConfigValue>? get activeConfig => _activeConfig;
  Map<String, RemoteConfigValue>? _activeConfig;

  /// Read-ahead getter
  void loadFromStorage() {
    // Note:
    // 1. we consistently check for null to avoid clobbering defined values
    //   in memory
    // 2. we defer awaiting to improve readability, as opposed to destructuring
    //   a Promise.all result, for example

    final lastFetchStatus = _storage.lastFetchStatus;
    if (lastFetchStatus != null) {
      _lastFetchStatus = lastFetchStatus;
    }

    final lastFetchTime = _storage.lastFetchTime;
    if (lastFetchTime != null) {
      _lastFetchTime = lastFetchTime;
    }

    final activeConfig = _storage.activeConfig;
    if (activeConfig != null) {
      _activeConfig = activeConfig;
    }
  }

  /// Write-through setters

  /// Sets the last fetch time
  void setLastFetchTime(DateTime? value) {
    _lastFetchTime = value;
    _storage.lastFetchTime = value;
  }

  /// Sets the last fetch status
  void setLastFetchStatus(RemoteConfigFetchStatus? value) {
    _lastFetchStatus = value;
    _storage.lastFetchStatus = value;
  }

  /// Sets the active config
  void setActiveConfig(Map<String, RemoteConfigValue> config) {
    _activeConfig = config;
    _storage.activeConfig = config;
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

extension _MapNullable<T> on T? {
  S? mapNullable<S>(S? Function(T) f) {
    if (this == null) {
      return null;
    }
    return f(this as T);
  }
}
