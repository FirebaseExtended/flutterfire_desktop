library cloud_functions_desktop;

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterfire_core_dart/flutterfire_core_dart.dart' as core_dart;
import 'package:flutterfire_functions_dart/flutterfire_functions_dart.dart'
    as functions_dart;
import 'package:meta/meta.dart';

/// Desktop implementation of FirebaseFunctionsPlatform for managing FirebaseFunctions
class FirebaseFunctionsDesktop extends FirebaseFunctionsPlatform {
  /// Constructs a FirebaseFunctionsDesktop
  FirebaseFunctionsDesktop(
      {required FirebaseApp app, String region = 'us-central1'})
      : _app = core_dart.Firebase.app(app.name),
        super(app, region);

  /// Called by PluginRegistry to register this plugin as the implementation for Desktop
  static void registerWith() {
    FirebaseFunctionsPlatform.instance =
        FirebaseFunctionsDesktop(app: Firebase.app());
  }

  final core_dart.FirebaseApp _app;

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
    required this.functions,
    String? origin,
    required String name,
    required HttpsCallableOptions options,
  }) : super(functions, origin, name, options);

  final FirebaseFunctionsDesktop functions;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    if (origin != null) {
      functions.dartFunctions.useFunctionsEmulator(
        origin!.substring(
          origin!.indexOf('://') + 3,
          origin!.lastIndexOf(':'),
        ),
        int.parse(
          origin!.substring(origin!.lastIndexOf(':') + 1),
        ),
      );
    }
    final result = await functions.dartFunctions
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
