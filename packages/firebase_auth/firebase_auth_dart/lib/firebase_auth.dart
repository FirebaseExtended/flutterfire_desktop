/// Support for Firebase authentication methods
/// with pure dart implmentation.
///
library firebase_auth_dart;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:googleapis/identitytoolkit/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

part 'src/firebase_auth.dart';
part 'src/firebase_auth_user.dart';
part 'src/firebase_auth_providers.dart';
part 'src/firebase_auth_exception.dart';
part 'src/firebase_auth_credential.dart';
part 'src/firebase_auth_user_credential.dart';
part 'src/firebase_auth_additional_user_info.dart';
part 'src/id_token.dart';
