/// Support for Firebase authentication methods
/// with pure dart implmentation.
///
library flutterfire_functions_dart;

import 'dart:convert';
import 'dart:io';
import 'package:flutterfire_core_dart/flutterfire_core_dart.dart';
import 'package:http/http.dart' as http;
part 'src/api.dart';

class FirebaseCloudFunctions {
  final FirebaseApp app;
  FirebaseCloudFunctions._({required this.app});
}
