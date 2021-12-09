/// Support for Firebase authentication methods
/// with pure dart implmentation.
///
library flutterfire_auth_dart;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:googleapis/identitytoolkit/v3.dart' as idp;
import 'package:googleapis_auth/auth_io.dart'
    if (dart.library.html) 'package:googleapis_auth/auth_browser.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'src/providers/email_auth.dart';
import 'src/providers/google_auth.dart';
import 'src/utils/jwt.dart';

export 'src/auth_provider.dart';
export 'src/providers/email_auth.dart';
export 'src/providers/facebook_auth.dart';
export 'src/providers/google_auth.dart';
export 'src/providers/oauth.dart';
export 'src/providers/twitter_auth.dart';

part 'src/additional_user_info.dart';
part 'src/api.dart';
part 'src/auth_credential.dart';
part 'src/firebase_auth.dart';
part 'src/firebase_auth_exception.dart';
part 'src/id_token_result.dart';
part 'src/user.dart';
part 'src/user_credential.dart';
part 'src/user_info.dart';
part 'src/user_metadata.dart';
part 'src/utils/persistence.dart';
