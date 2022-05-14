// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_remote_config_desktop;

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;
import 'package:firebase_remote_config_dart/firebase_remote_config_dart.dart'
    as remote_config;
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';

/// Desktop implementation of FirebaseRemoteConfigPlatform for managing FirebaseRemoteConfig
class FirebaseRemoteConfigDesktop extends FirebaseRemoteConfigPlatform {
  /// Constructs a FirebaseRemoteConfigDesktop
  FirebaseRemoteConfigDesktop({
    required FirebaseApp app,
  })  : _app = core_dart.Firebase.app(app.name),
        super(appInstance: app);

  FirebaseRemoteConfigDesktop._()
      : _app = null,
        super(appInstance: null);

  /// Called by PluginRegistry to register this plugin as the implementation for Desktop
  static void registerWith() {
    FirebaseRemoteConfigPlatform.instance =
        FirebaseRemoteConfigDesktop.instance;
  }

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  ///
  // ignore: prefer_constructors_over_static_methods
  static FirebaseRemoteConfigDesktop get instance {
    return FirebaseRemoteConfigDesktop._();
  }

  @override
  FirebaseRemoteConfigPlatform delegateFor({
    FirebaseApp? app,
  }) =>
      FirebaseRemoteConfigDesktop(app: app ?? Firebase.app());

  final core_dart.FirebaseApp? _app;
  late final remote_config.FirebaseRemoteConfig _remoteConfig =
      remote_config.FirebaseRemoteConfig.instanceFor(app: _app);

  /// Sets any initial values on the instance.
  ///
  /// Platforms with Method Channels can provide constant values to be
  /// available before the instance has initialized to prevent unnecessary
  /// async calls.
  @override
  FirebaseRemoteConfigPlatform setInitialValues({
    required Map remoteConfigValues,
  }) {
    if (!remoteConfigValues.containsKey('fetchTimeout')) {
      remoteConfigValues['fetchTimeout'] = 60;
    }
    if (!remoteConfigValues.containsKey('minimumFetchInterval')) {
      remoteConfigValues['minimumFetchInterval'] = 12 * 60;
    }
    if (!remoteConfigValues.containsKey('lastFetchStatus')) {
      remoteConfigValues['lastFetchStatus'] = 'noFetchYet';
    }
    if (!remoteConfigValues.containsKey('lastFetchTime')) {
      remoteConfigValues['lastFetchTime'] = 0;
    }
    if (!remoteConfigValues.containsKey('parameters')) {
      remoteConfigValues['parameters'] = {};
    }
    _remoteConfig.setInitialValues(remoteConfigValues: remoteConfigValues);
    return this;
  }

  @override

  /// Returns the [DateTime] of the last successful fetch.
  ///
  /// If no successful fetch has been made a [DateTime] representing
  /// the epoch (1970-01-01 UTC) is returned.
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;

  @override

  /// Returns the status of the last fetch attempt.

  RemoteConfigFetchStatus get lastFetchStatus =>
      RemoteConfigFetchStatus.values[_remoteConfig.lastFetchStatus.index];

  /// Returns the [RemoteConfigSettings] of the current instance.

  @override
  RemoteConfigSettings get settings => RemoteConfigSettings(
        fetchTimeout: _remoteConfig.settings.fetchTimeout,
        minimumFetchInterval: _remoteConfig.settings.minimumFetchInterval,
      );

  /// Makes the last fetched config available to getters.
  ///
  /// Returns a [bool] that is true if the config parameters
  /// were activated. Returns a [bool] that is false if the
  /// config parameters were already activated.
  @override
  Future<bool> activate() => _remoteConfig.activate();

  /// Ensures the last activated config are available to getters.
  @override
  Future<void> ensureInitialized() => _remoteConfig.ensureInitialized();

  /// Fetches and caches configuration from the Remote Config service.
  @override
  Future<void> fetch() => _remoteConfig.fetch();

  /// Performs a fetch and activate operation, as a convenience.
  ///
  /// Returns [bool] in the same way that is done for [activate].
  @override
  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();

  /// Returns a Map of all Remote Config parameters.
  @override
  Map<String, RemoteConfigValue> getAll() => {
        for (final entry in _remoteConfig.getAll().entries)
          entry.key: RemoteConfigValue(
            utf8.encode(entry.value.asString()),
            ValueSource.values[entry.value.source.index],
          ),
      };

  /// Gets the value for a given key as a bool.
  @override
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// Gets the value for a given key as an int.
  @override
  int getInt(String key) => _remoteConfig.getInt(key);

  /// Gets the value for a given key as a double.
  @override
  double getDouble(String key) => _remoteConfig.getDouble(key);

  /// Gets the value for a given key as a String.
  @override
  String getString(String key) => _remoteConfig.getString(key);

  /// Gets the [RemoteConfigValue] for a given key.
  @override
  RemoteConfigValue getValue(String key) {
    final value = _remoteConfig.getValue(key);
    return RemoteConfigValue(
      utf8.encode(value.asString()),
      ValueSource.values[value.source.index],
    );
  }

  /// Sets the [RemoteConfigSettings] for the current instance.
  @override
  Future<void> setConfigSettings(
    RemoteConfigSettings remoteConfigSettings,
  ) async {
    await _remoteConfig.setConfigSettings(
      remote_config.RemoteConfigSettings(
        fetchTimeout: remoteConfigSettings.fetchTimeout,
        minimumFetchInterval: remoteConfigSettings.minimumFetchInterval,
      ),
    );
  }

  /// Sets the default parameter values for the current instance.
  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) =>
      _remoteConfig.setDefaults(defaultParameters);
}
