library cloud_functions_desktop;

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;
import 'package:firebase_functions_dart/firebase_functions_dart.dart'
    as functions_dart;
import 'package:meta/meta.dart';

/// Desktop implementation of FirebaseFunctionsPlatform for managing FirebaseFunctions
class FirebaseFunctionsDesktop extends FirebaseFunctionsPlatform {
  /// Constructs a FirebaseFunctionsDesktop
  FirebaseFunctionsDesktop({
    required FirebaseApp app,
    String region = functions_dart.FirebaseFunctions.defaultRegion,
  })  : _app = core_dart.Firebase.app(app.name),
        super(app, region);

  FirebaseFunctionsDesktop._()
      : _app = null,
        super(null, functions_dart.FirebaseFunctions.defaultRegion);

  /// Called by PluginRegistry to register this plugin as the implementation for Desktop
  static void registerWith() {
    FirebaseFunctionsPlatform.instance = FirebaseFunctionsDesktop.instance;
  }

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  ///
  // ignore: prefer_constructors_over_static_methods
  static FirebaseFunctionsDesktop get instance {
    return FirebaseFunctionsDesktop._();
  }

  final core_dart.FirebaseApp? _app;

  /// The dart functions instance for this app
  @visibleForTesting
  late final functions_dart.FirebaseFunctions dartFunctions =
      functions_dart.FirebaseFunctions.instanceFor(
    app: _app,
    region: region,
  );

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) =>
      FirebaseFunctionsDesktop(app: app ?? Firebase.app(), region: region);
  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) =>
      HttpsCallableDesktop(
        functions: this,
        origin: origin,
        name: name,
        options: options,
      );
}

/// Desktop implementation of HttpsCallablePlatform for managing HttpsCallable
/// instances.
class HttpsCallableDesktop extends HttpsCallablePlatform {
  /// Constructs a HttpsCallableDesktop
  HttpsCallableDesktop({
    required FirebaseFunctionsDesktop functions,
    String? origin,
    required String name,
    required HttpsCallableOptions options,
  })  : _dartFunctions = functions.dartFunctions,
        super(functions, origin, name, options);

  /// The dart functions instance for accessing the cloud functions API
  final functions_dart.FirebaseFunctions _dartFunctions;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    if (origin != null) {
      _dartFunctions.useFunctionsEmulator(
        origin!.substring(
          origin!.indexOf('://') + 3,
          origin!.lastIndexOf(':'),
        ),
        int.parse(
          origin!.substring(origin!.lastIndexOf(':') + 1),
        ),
      );
    }
    final result = await _dartFunctions
        .httpsCallable(
          name,
          options: functions_dart.HttpsCallableOptions(
            timeout: options.timeout,
          ),
        )
        .call(parameters);
    return result.data;
  }
}
