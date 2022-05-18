part of firebase_app_installations;

class FirebaseAppInstallationsDart {
  /// The entry point for the [FirebaseAppInstallationsDart] class.
  FirebaseAppInstallationsDart({FirebaseApp? app});

  /// Stub initializer to allow the [registerWith] to create an instance without
  /// registering the web delegates or listeners.
  FirebaseAppInstallationsDart._();

  /// Returns an instance of [FirebaseAppInstallationsDart].
  static FirebaseAppInstallationsDart get instance {
    return FirebaseAppInstallationsDart._();
  }

  FirebaseAppInstallationsDart instanceFor({required FirebaseApp app}) {
    return FirebaseAppInstallationsDart(app: app);
  }

  // Future<void> delete() async {}

  // Future<String> getId() async {}

  // Future<String> getToken(bool forceRefresh) async {}
}
