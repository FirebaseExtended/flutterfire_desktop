import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mock = MockFirebaseCore();

  const testOptions = FirebaseOptions(
    apiKey: 'apiKey',
    appId: 'appId',
    messagingSenderId: 'messagingSenderId',
    projectId: 'projectId',
  );

  const testAppName = 'testApp';
  group('$Firebase', () {
    setUp(() async {
      clearInteractions(mock);
      Firebase.delegatePackingProperty = mock;

      final platformApp = FirebaseAppPlatform(testAppName, testOptions);

      when(mock.apps).thenReturn([platformApp]);
      when(mock.app(testAppName)).thenReturn(platformApp);
      when(mock.initializeApp(name: testAppName, options: testOptions))
          .thenAnswer((_) {
        return Future.value(platformApp);
      });
    });

    test('.apps', () {
      final apps = Firebase.apps;
      verify(mock.apps);
      expect(apps[0], Firebase.app(testAppName));
    });

    test('.app()', () {
      final app = Firebase.app(testAppName);
      verify(mock.app(testAppName));

      expect(app.name, testAppName);
      expect(app.options, testOptions);
    });

    test('.initializeApp()', () async {
      final initializedApp =
          await Firebase.initializeApp(name: testAppName, options: testOptions);
      final app = Firebase.app(testAppName);

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(name: testAppName, options: testOptions),
        mock.app(testAppName),
      ]);
    });
  });
}

class MockFirebaseCore extends Mock
    with
        // ignore: prefer_mixin, plugin_platform_interface needs to migrate to use `mixin`
        MockPlatformInterfaceMixin
    implements
        FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return super.noSuchMethod(
      Invocation.method(#app, [name]),
      returnValue: FakeFirebaseAppPlatform(),
      returnValueForMissingStub: FakeFirebaseAppPlatform(),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #initializeApp,
        const [],
        {
          #name: name,
          #options: options,
        },
      ),
      returnValue: Future.value(FakeFirebaseAppPlatform()),
      returnValueForMissingStub: Future.value(FakeFirebaseAppPlatform()),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return super.noSuchMethod(
      Invocation.getter(#apps),
      returnValue: <FirebaseAppPlatform>[],
      returnValueForMissingStub: <FirebaseAppPlatform>[],
    );
  }
}

// ignore: avoid_implementing_value_types
class FakeFirebaseAppPlatform extends Fake implements FirebaseAppPlatform {}
