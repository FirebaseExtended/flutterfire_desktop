// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_remote_config_dart;

import 'dart:async';

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebaseapis/firebaseremoteconfig/v1.dart' as api;
import 'package:googleapis_auth/auth_io.dart';
import 'package:meta/meta.dart';
import 'package:storagebox/storagebox.dart';

import 'src/remote_config_settings.dart';
import 'src/remote_config_status.dart';
import 'src/remote_config_value.dart';

export 'src/remote_config_settings.dart';
export 'src/remote_config_status.dart';
export 'src/remote_config_value.dart';

part 'src/internal/api.dart';
part 'src/internal/storage.dart';

/// The entry point for accessing Remote Config.
///
/// You can get an instance by calling [FirebaseRemoteConfig.instance]. Note
/// [FirebaseRemoteConfig.instance] is async.
// TODO: The flutter implementation uses a ChangeNotifier to let someone listen should we use StateNotifier?
class FirebaseRemoteConfig {
  /// Creates a new instance of FirebaseRemoteConfig
  @visibleForTesting
  FirebaseRemoteConfig({
    required this.app,
    this.namespace = 'firebase',
  }) : storage = _RemoteConfigStorage(app.options.appId, app.name, namespace);

  // Cached instances of [FirebaseRemoteConfig].
  static final Map<String, Map<String, FirebaseRemoteConfig>>
      _firebaseRemoteConfigInstances = {};

  /// The [FirebaseApp] this instance was initialized with.
  final FirebaseApp app;

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseRemoteConfig get instance {
    return FirebaseRemoteConfig.instanceFor(app: Firebase.app());
  }

  /// Returns an instance using the specified [FirebaseApp].
  // ignore: prefer_constructors_over_static_methods
  static FirebaseRemoteConfig instanceFor({
    FirebaseApp? app,
    String namespace = 'firebase',
  }) {
    final _app = app ?? Firebase.app();
    if (_firebaseRemoteConfigInstances[_app.name] == null) {
      _firebaseRemoteConfigInstances[_app.name] = {};
    }
    return _firebaseRemoteConfigInstances[_app.name]!.putIfAbsent(
      namespace,
      () => FirebaseRemoteConfig(app: _app, namespace: namespace),
    );
  }

  @visibleForTesting
  // ignore: library_private_types_in_public_api, public_member_api_docs
  late final _RemoteConfigStorageCache storageCache =
      _RemoteConfigStorageCache(storage);
  @visibleForTesting
  // ignore: library_private_types_in_public_api, public_member_api_docs
  final _RemoteConfigStorage storage;

  /// The namespace of the remote config instance
  final String namespace;

  /// Returns the [DateTime] of the last successful fetch.
  ///
  /// If no successful fetch has been made a [DateTime] representing
  /// the epoch (1970-01-01 UTC) is returned.
  DateTime get lastFetchTime =>
      storageCache.lastFetchTime ?? DateTime.fromMicrosecondsSinceEpoch(0);

  /// Returns the status of the last fetch attempt.
  RemoteConfigFetchStatus get lastFetchStatus =>
      storageCache.lastFetchStatus ?? RemoteConfigFetchStatus.noFetchYet;

  /// Returns a copy of the [RemoteConfigSettings] of the current instance.
  RemoteConfigSettings get settings => RemoteConfigSettings(
        fetchTimeout: _settings.fetchTimeout,
        minimumFetchInterval: _settings.minimumFetchInterval,
      );
  RemoteConfigSettings _settings = RemoteConfigSettings();

  /// Default parameters set via [setDefaults]
  Map<String, Object?> _defaultConfig = {};

  /// Api
  @visibleForTesting
  late RemoteConfigApiClient api = RemoteConfigApiClient(
    app.options.projectId,
    namespace,
    app.options.apiKey,
    app.options.appId,
    storage,
    storageCache,
  );

  /// Makes the last fetched config available to getters.
  ///
  /// Returns a [bool] that is true if the config parameters
  /// were activated. Returns a [bool] that is false if the
  /// config parameters were already activated.
  Future<bool> activate() async {
    final lastSuccessfulFetchResponse =
        storage.getLastSuccessfulFetchResponse();

    if (lastSuccessfulFetchResponse == null) {
      return false;
    } else {
      final newConfig = <String, RemoteConfigValue>{
        for (final entry in lastSuccessfulFetchResponse.entries)
          entry.key: RemoteConfigValue(entry.value, ValueSource.valueRemote)
      };
      storageCache.setActiveConfig(newConfig);
      return true;
    }
  }

  final _initialized = Completer<void>();

  /// Ensures the last activated config are available to getters.
  Future<void> ensureInitialized() async {
    // Somewhat unnecessary for desktop because we do synchronous file reads for storage
    // Will be necessary if we ever support pure dart on web
    if (!_initialized.isCompleted) {
      await storageCache.loadFromStorage().then((_) {
        _initialized.complete();
      });
    }
    return _initialized.future;
  }

  /// Fetches and caches configuration from the Remote Config service.
  Future<void> fetch() async {
    try {
      await api
          .fetch(cacheMaxAge: settings.minimumFetchInterval)
          .timeout(settings.fetchTimeout);
    } on TimeoutException {
      storageCache.setLastFetchStatus(RemoteConfigFetchStatus.throttle);
      rethrow; // TODO: Throw Firebase Exception
    } on Exception {
      storageCache.setLastFetchStatus(RemoteConfigFetchStatus.failure);
      rethrow; // TODO: Throw Firebase Exception
    }
    storageCache.setLastFetchStatus(RemoteConfigFetchStatus.success);
  }

  /// Performs a fetch and activate operation, as a convenience.
  ///
  /// Returns [bool] in the same way that is done for [activate].
  Future<bool> fetchAndActivate() async {
    await fetch();
    return activate();
  }

  /// Returns a Map of all Remote Config parameters.
  Map<String, RemoteConfigValue> getAll() {
    final allKeys = {
      ...?storageCache.activeConfig?.keys,
      ..._defaultConfig.keys
    };
    // Get the value for each key, respecting the default config
    return {for (final key in allKeys) key: getValue(key)};
  }

  /// Gets the value for a given key as a bool.
  bool getBool(String key) => getValue(key).asBool();

  /// Gets the value for a given key as an int.
  int getInt(String key) => getValue(key).asInt();

  /// Gets the value for a given key as a double.
  double getDouble(String key) => getValue(key).asDouble();

  /// Gets the value for a given key as a String.
  String getString(String key) => getValue(key).asString();

  /// Gets the [RemoteConfigValue] for a given key.
  RemoteConfigValue getValue(String key) {
    assert(
      _initialized.isCompleted,
      'Please ensure ensureInitialized is called prior to getting a remote config value',
    );
    return storage.activeConfig?[key] ??
        RemoteConfigValue(
          _defaultConfig[key].mapNullable((v) => '$v'),
          ValueSource.valueDefault,
        );
  }

  /// Sets the [RemoteConfigSettings] for the current instance.
  Future<void> setConfigSettings(
    RemoteConfigSettings remoteConfigSettings,
  ) async {
    assert(!remoteConfigSettings.fetchTimeout.isNegative);
    assert(!remoteConfigSettings.minimumFetchInterval.isNegative);
    // To be consistent with iOS fetchTimeout is set to the default
    // 1 minute (60 seconds) if an attempt is made to set it to zero seconds.
    if (remoteConfigSettings.fetchTimeout.inSeconds == 0) {
      remoteConfigSettings.fetchTimeout = const Duration(seconds: 60);
    }
    _settings = remoteConfigSettings;
  }

  /// Sets the default parameter values for the current instance.
  Future<void> setDefaults(Map<String, dynamic> defaultConfig) async {
    _defaultConfig = {...defaultConfig};
  }

  /// Sets values to be immediately available
  void setInitialValues({Map? remoteConfigValues}) {
    if (remoteConfigValues == null) {
      return;
    }
    final fetchTimeout = Duration(seconds: remoteConfigValues['fetchTimeout']);
    final minimumFetchInterval =
        Duration(seconds: remoteConfigValues['minimumFetchInterval']);
    final lastFetchMillis = remoteConfigValues['lastFetchTime'];
    final lastFetchStatus = remoteConfigValues['lastFetchStatus'];

    _settings = RemoteConfigSettings(
      fetchTimeout: fetchTimeout,
      minimumFetchInterval: minimumFetchInterval,
    );

    storageCache.setLastFetchTime(
      DateTime.fromMillisecondsSinceEpoch(lastFetchMillis),
    );
    storageCache.setLastFetchStatus(_parseFetchStatus(lastFetchStatus));
    storageCache.setActiveConfig(
      _parseParameters(remoteConfigValues['parameters']),
    );
  }

  RemoteConfigFetchStatus _parseFetchStatus(String? status) {
    try {
      return status.mapNullable(RemoteConfigFetchStatus.values.byName) ??
          RemoteConfigFetchStatus.noFetchYet;
    } on Exception {
      return RemoteConfigFetchStatus.noFetchYet;
    }
  }

  Map<String, RemoteConfigValue> _parseParameters(
    Map<dynamic, dynamic> rawParameters,
  ) {
    final parameters = <String, RemoteConfigValue>{};
    for (final key in rawParameters.keys) {
      final rawValue = rawParameters[key] as Map;
      parameters[key] = RemoteConfigValue(
        rawValue['value'],
        _parseValueSource(rawValue['source']),
      );
    }
    return parameters;
  }

  ValueSource _parseValueSource(String? sourceStr) {
    switch (sourceStr) {
      case 'remote':
        return ValueSource.valueRemote;
      case 'default':
        return ValueSource.valueDefault;
      case 'static':
        return ValueSource.valueStatic;
      default:
        return ValueSource.valueStatic;
    }
  }
}
