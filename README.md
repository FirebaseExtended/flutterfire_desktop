# FlutterFire Desktop

A work in progress pure Dart implementation of Firebase with initial support aimed at FlutterFire for Linux & Windows.

A FlutterFire dev preview release will be available soon making these packages available for Linux and Windows.

Learn more about the current progress of this project in [our blog](https://invertase.io/blog/announcing-flutterfire-desktop).

## Usage

To use this plugin as FlutterFire's implementation for Desktop, add it to your app's `pubspec.yaml` along with the main plugin:

```yaml
dependencies:
  firebase_auth: ^3.1.5
  firebase_auth_desktop: ^0.1.1-dev.0
  firebase_core: ^1.9.0
  firebase_core_desktop: ^0.1.1-dev.0
```

## Firebase App Initialization

Unlike FlutterFire for mobile and web platforms, the initialization in Desktop is done from Dart, which means there are no additional config files required.
### DEFAULT app
To initialize the default app, provide only options without a name.
 ```dart
 await Firebase.initializeApp(
   options: const FirebaseOptions(
     apiKey: '...',
     appId: '...',
     messagingSenderId: '...',
     projectId: '...',
   )
 );
 ```
### Secondary app
 ```dart
 await Firebase.initializeApp(
   name: 'SecondaryApp',
   options: const FirebaseOptions(
     apiKey: '...',
     appId: '...',
     messagingSenderId: '...',
     projectId: '...',
   )
 );
 ```

## Contributing

This is a community project, contributions to help it progress faster are welcome:
1. Before starting, please read the [contribution guide of FlutterFire](https://github.com/FirebaseExtended/flutterfire/blob/master/CONTRIBUTING.md).
2. Refer to the [projects board](https://github.com/invertase/flutterfire_desktop/projects) to see the current progress & planned future work.

## Notes

If you get an error while building linux application, run

```sudo apt install libwebkit2gtk-4.0-dev -y```

You may also have to uninstall flutter(snap) and install the Flutter git version in directory of your choice. You can do so by cloning the git repo using

```git clone https://github.com/flutter/flutter.git```
