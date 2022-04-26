// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_remote_config_dart;

import 'dart:convert';

import 'package:firebase_auth_dart/firebase_auth_dart.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:http/http.dart';

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
/// You can get an instance by calling [RemoteConfig.instance]. Note
/// [RemoteConfig.instance] is async.
// TODO(TimWhiting): Figure out how to introduce ChangeNotifier like class
class RemoteConfig {
  RemoteConfig._({required this.app})
      : _storage = _RemoveConfigStorageCache(
          _RemoteConfigStorage(app.options.appId, app.name, ''),
        );

  // Cached instances of [FirebaseRemoteConfig].
  static final Map<String, RemoteConfig> _firebaseRemoteConfigInstances = {};

  /// The [FirebaseApp] this instance was initialized with.
  final FirebaseApp app;

  /// Returns an instance using the default [FirebaseApp].
  static RemoteConfig get instance {
    return RemoteConfig.instanceFor(app: Firebase.app());
  }

  /// Returns an instance using the specified [FirebaseApp].
  // ignore: prefer_constructors_over_static_methods
  static RemoteConfig instanceFor({required FirebaseApp app}) {
    return _firebaseRemoteConfigInstances.putIfAbsent(app.name, () {
      return RemoteConfig._(app: app);
    });
  }

  // final _api = _RemoteConfigApiClient();
  final _RemoveConfigStorageCache _storage;

  /// Returns the [DateTime] of the last successful fetch.
  ///
  /// If no successful fetch has been made a [DateTime] representing
  /// the epoch (1970-01-01 UTC) is returned.
  DateTime get lastFetchTime =>
      _storage.lastFetchTime ?? DateTime.fromMicrosecondsSinceEpoch(0);

  /// Returns the status of the last fetch attempt.
  RemoteConfigFetchStatus get lastFetchStatus =>
      _storage.lastFetchStatus ?? RemoteConfigFetchStatus.noFetchYet;

  /// Returns a copy of the [RemoteConfigSettings] of the current instance.
  RemoteConfigSettings get settings => RemoteConfigSettings(
        fetchTimeout: _settings.fetchTimeout,
        minimumFetchInterval: _settings.minimumFetchInterval,
      );
  RemoteConfigSettings _settings = RemoteConfigSettings();

  /// Default parameters set via [setDefaults]
  Map<String, dynamic> _defaultParameters = {};

  /// Makes the last fetched config available to getters.
  ///
  /// Returns a [bool] that is true if the config parameters
  /// were activated. Returns a [bool] that is false if the
  /// config parameters were already activated.
  Future<bool> activate() async {
    // TODO: Load config from storage
    // final bool configChanged
    // return configChanged;

    return false;
  }

  /// Ensures the last activated config are available to getters.
  Future<void> ensureInitialized() async {
    // Unnecessary for desktop because we do synchronous file reads for storage
    // Will be necessary if we ever support pure dart on web
  }

  /// Fetches and caches configuration from the Remote Config service.
  Future<void> fetch() async {
    // TODO: Implement & wrap in try / catch etc
    // await _api.fetch();
    // TODO: Update these parameters in storage
    // _lastFetchTime = DateTime.now();
    // _lastFetchStatus = RemoteConfigFetchStatus.success;
    // _lastFetchedConfig = {};
  }

  /// Performs a fetch and activate operation, as a convenience.
  ///
  /// Returns [bool] in the same way that is done for [activate].
  Future<bool> fetchAndActivate() async {
    await fetch();
    return activate();
  }

  /// Returns a Map of all Remote Config parameters.
  Map<String, RemoteConfigValue>? getAll() {
    return _storage.activeConfig;
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
  RemoteConfigValue getValue(String key) =>
      _storage.activeConfig?[key] ??
      RemoteConfigValue(
        const Utf8Codec().encode('${_defaultParameters[key]}'),
        ValueSource.valueDefault,
      );

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
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    // TODO: Copy rather than trusting user to not mutate?
    _defaultParameters = defaultParameters;
  }
}
