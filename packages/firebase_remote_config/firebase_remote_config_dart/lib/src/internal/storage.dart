part of '../../firebase_remote_config_dart.dart';

class _RemoteConfigStorage {
  _RemoteConfigStorage(this.appId, this.appName, this.namespace);
  final String appId;
  final String appName;
  final String namespace;
  final StorageBox _storageBox = StorageBox('firebase_remote_config');
  static const activeConfigKey = 'active_config';
  static const lastFetchStatusKey = 'last_fetch_status';
  static const lastSuccessfulFetchTimeKey =
      'last_successful_fetch_timestamp_millis';
  static const lastSuccessfulFetchKey = 'last_successful_fetch_response';

  // TODO: Do we need these in storage?
  // static const activeConfigEtagKey = 'active_config_etag';
  // static const settingsKey = 'settings';
  // static const throttleMetadataKey = 'throttle_metadata';

  DateTime? get lastFetchTime =>
      (_storageBox[lastSuccessfulFetchTimeKey] as int?)
          .mapNullable(DateTime.fromMicrosecondsSinceEpoch);

  /// Sets the last fetch time
  set lastFetchTime(DateTime? value) {
    if (value == null) {
      _storageBox.remove(lastSuccessfulFetchKey);
      return;
    }
    _storageBox[lastSuccessfulFetchTimeKey] = value.microsecondsSinceEpoch;
  }

  RemoteConfigFetchStatus? get lastFetchStatus =>
      (_storageBox[lastFetchStatusKey] as String?)
          .mapNullable(RemoteConfigFetchStatus.values.byName);

  /// Sets the last fetch status
  set lastFetchStatus(RemoteConfigFetchStatus? value) {
    if (value == null) {
      _storageBox.remove(lastFetchStatusKey);
      return;
    }
    _storageBox[lastFetchStatusKey] = value.name;
  }

  Map<String, RemoteConfigValue>? get activeConfig {
    final config = _storageBox[activeConfigKey] as Map<String, Object?>?;
    if (config == null) {
      return null;
    }
    return {
      for (final entry in config.entries)
        if (entry.value != null)
          entry.key: RemoteConfigValue.fromJson(
            entry.value! as Map<String, Object?>,
          )
    };
  }

  set activeConfig(Map<String, RemoteConfigValue>? config) {
    if (config == null) {
      _storageBox.remove(activeConfigKey);
      return;
    }
    _storageBox[activeConfigKey] = {
      for (final entry in config.entries) entry.key: entry.value.toJson(),
    };
  }

  Map? getLastSuccessfulFetchResponse() {
    return _storageBox[lastSuccessfulFetchKey].mapNullable((v) => v as Map);
  }

  void setLastSuccessfulFetchResponse(Map remoteConfig) {
    _storageBox[lastSuccessfulFetchKey] = remoteConfig;
  }
}

/// A memory cache layer over storage to support the SDK's synchronous read requirements.
class _RemoteConfigStorageCache {
  _RemoteConfigStorageCache(_RemoteConfigStorage storage) : _storage = storage;
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
  Future<void> loadFromStorage() async {
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

extension _MapNullable<T> on T? {
  S? mapNullable<S>(S? Function(T) f) {
    if (this == null) {
      return null;
    }
    return f(this as T);
  }
}
