// ignore_for_file: require_trailing_commas
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// TODO: Endorse this plugin
import 'package:firebase_core_desktop/firebase_core_desktop.dart'
    as core_desktop;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:cloud_functions_desktop/cloud_functions_desktop.dart';
import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';

FirebaseOptions get firebaseOptions => const FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
    );
late FirebaseFunctions functions;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final core = core_desktop.FirebaseCore();
  FirebasePlatform.instance = core;
  // ignore: invalid_use_of_visible_for_testing_member
  Firebase.delegatePackingProperty = core;

  final app =
      await Firebase.initializeApp(name: 'app', options: firebaseOptions);
  FirebaseFunctionsPlatform.instance = FirebaseFunctionsDesktop(app: app);
  functions = FirebaseFunctions.instanceFor(app: app)
    ..useFunctionsEmulator('localhost', 5001);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List fruit = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Functions Example'),
        ),
        body: Center(
            child: ListView.builder(
                itemCount: fruit.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${fruit[index]}'),
                  );
                })),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () async {
              // See index.js in the functions folder for the example function we
              // are using for this example
              final HttpsCallable callable = functions.httpsCallable(
                  'listFruit',
                  options: HttpsCallableOptions(
                      timeout: const Duration(seconds: 5)));

              await callable().then((v) {
                setState(() {
                  fruit.clear();
                  v.data.forEach((f) {
                    fruit.add(f);
                  });
                });
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('ERROR: $e'),
                ));
              });
            },
            label: const Text('Call Function'),
            icon: const Icon(Icons.cloud),
            backgroundColor: Colors.deepOrange,
          ),
        ),
      ),
    );
  }
}
