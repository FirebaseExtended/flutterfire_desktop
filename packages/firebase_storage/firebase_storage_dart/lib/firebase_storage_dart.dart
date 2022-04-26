/// Support for doing something awesome.
///
/// More dartdocs go here.
library firebase_storage_dart;

import 'dart:async';
import 'dart:convert' show utf8, base64;
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:firebase_storage_dart/src/api/api.dart';
import 'package:firebase_storage_dart/src/implementations/location.dart';
import 'package:firebase_storage_dart/src/implementations/paths.dart' as paths;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:firebase_storage_dart/src/data_models/full_metadata.dart';
import 'package:firebase_storage_dart/src/data_models/list_options.dart';
import 'package:firebase_storage_dart/src/data_models/put_string_format.dart';
import 'package:firebase_storage_dart/src/data_models/settable_metadata.dart';
import 'package:firebase_storage_dart/src/data_models/task_state.dart';

import 'package:firebase_storage_dart/src/utils.dart';

// TODO: Export any libraries intended for clients of this package.
// part 'src/utils.dart';
part 'src/firebase_storage.dart';
part 'src/reference.dart';
part 'src/list_result.dart';
part 'src/task.dart';
part 'src/task_snapshot.dart';
