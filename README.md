# Firebase's Dart SDK

 <a href="https://invertase.link/discord">
   <img src="https://img.shields.io/discord/295953187817521152.svg?style=flat-square&colorA=7289da&label=Chat%20on%20Discord" alt="Chat on Discord">
 </a>


The Dart SDK allows Flutter and Dart apps to consume Firebase services. 

It is an __early-stage, experimental__ pure-Dart implementation of Firebase SDKs, without wrapping the existing Android, iOS, web, or C++ SDKs. The initial work is focused on supporting Firebase for Linux and Windows platforms.

## Usage

To use this plugin, add the following dependencies to your app's `pubspec.yaml` file, along with the main plugin:

```yaml
dependencies:
  firebase_auth: ^3.1.5
  firebase_auth_desktop: ^0.1.1-dev.0
  firebase_core: ^1.9.0
  firebase_core_desktop: ^0.1.1-dev.0
```

## Firebase App Initialization

Unlike the Firebase Flutter SDK, the Firebase initialization is done from Dart code, which means no additional config files are required.

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
