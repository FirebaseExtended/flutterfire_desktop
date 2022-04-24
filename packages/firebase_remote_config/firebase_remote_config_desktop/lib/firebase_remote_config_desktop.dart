// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_remote_config_desktop;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;

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

  final core_dart.FirebaseApp? _app;

  @override
  FirebaseRemoteConfigPlatform delegateFor({
    FirebaseApp? app,
  }) =>
      FirebaseRemoteConfigDesktop(app: app ?? Firebase.app());
}
