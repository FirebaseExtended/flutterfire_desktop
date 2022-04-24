// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_remote_config_dart;

import 'dart:convert';

import 'package:firebase_core_dart/firebase_core_dart.dart';

import 'src/remote_config_settings.dart';
import 'src/remote_config_status.dart';
import 'src/remote_config_value.dart';
export 'src/remote_config_settings.dart';
export 'src/remote_config_status.dart';
export 'src/remote_config_value.dart';

part 'src/internal/api.dart';

/// The entry point for accessing Remote Config.
///
/// You can get an instance by calling [RemoteConfig.instance]. Note
/// [RemoteConfig.instance] is async.
// TODO(TimWhiting): Figure out how to introduce ChangeNotifier like class
class RemoteConfig {
  RemoteConfig._({required this.app});

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

  RemoteConfigApi _api;

  /// Returns the [DateTime] of the last successful fetch.
  ///
  /// If no successful fetch has been made a [DateTime] representing
  /// the epoch (1970-01-01 UTC) is returned.
  DateTime get lastFetchTime {}
  final DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns the status of the last fetch attempt.
  RemoteConfigFetchStatus get lastFetchStatus {}
  final RemoteConfigFetchStatus _lastFetchStatus =
      RemoteConfigFetchStatus.noFetchYet;

  /// Returns the [RemoteConfigSettings] of the current instance.
  RemoteConfigSettings get settings {}
  RemoteConfigSettings _settings = RemoteConfigSettings();

  /// Makes the last fetched config available to getters.
  ///
  /// Returns a [bool] that is true if the config parameters
  /// were activated. Returns a [bool] that is false if the
  /// config parameters were already activated.
  Future<bool> activate() async {
    final bool configChanged = await _api.activate();
    notifyListeners();
    return configChanged;
  }

  /// Ensures the last activated config are available to getters.
  Future<void> ensureInitialized() {
    return _api.ensureInitialized();
  }

  /// Fetches and caches configuration from the Remote Config service.
  Future<void> fetch() async {
    // TODO: Implement
    await _api.fetch();
    _lastFetchedConfig = {};
  }

  /// Performs a fetch and activate operation, as a convenience.
  ///
  /// Returns [bool] in the same way that is done for [activate].
  Future<bool> fetchAndActivate() async {
    final bool configChanged = await _api.fetchAndActivate();
    notifyListeners();
    _lastFetchedConfig = {};
    return configChanged;
  }

  Map<String, RemoteConfigValue> _lastFetchedConfig = {};
  Map<String, dynamic> _defaultParameters;

  /// Returns a Map of all Remote Config parameters.
  Map<String, RemoteConfigValue> getAll() {
    return _lastFetchedConfig;
  }

  /// Gets the value for a given key as a bool.
  bool getBool(String key) {
    return _lastFetchedConfig[key]?.asBool() ??
        _defaultParameters[key]! as bool;
  }

  /// Gets the value for a given key as an int.
  int getInt(String key) {
    return _lastFetchedConfig[key]?.asInt() ?? _defaultParameters[key]! as int;
  }

  /// Gets the value for a given key as a double.
  double getDouble(String key) {
    return _lastFetchedConfig[key]?.asDouble() ??
        _defaultParameters[key]! as double;
  }

  /// Gets the value for a given key as a String.
  String getString(String key) {
    return _lastFetchedConfig[key]?.asString() ??
        _defaultParameters[key]! as String;
  }

  /// Gets the [RemoteConfigValue] for a given key.
  RemoteConfigValue getValue(String key) {
    return _lastFetchedConfig[key] ??
        RemoteConfigValue(
          const Utf8Codec().encode('${_defaultParameters[key]}'),
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
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    _defaultParameters = defaultParameters;
  }
}
